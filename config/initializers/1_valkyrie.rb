# frozen_string_literal: true
require 'faraday/multipart'

Valkyrie::MetadataAdapter.register(
  Valkyrie::Persistence::Fedora::MetadataAdapter.new(
    connection:     ::Ldp::Client.new(Hyrax.config.fedora_connection_builder.call(
      ENV.fetch('FEDORA6_URL') { "http://localhost:8985/fcrepo/rest" }
    )),
    base_path:      ENV.fetch('FEDORA_BASE_PATH', Rails.env).gsub(/^\/|\/$/, ''),
    schema:         Valkyrie::Persistence::Fedora::PermissiveSchema.new(Hyrax::SimpleSchemaLoader.new.permissive_schema_for_valkrie_adapter),
    fedora_version: 6
  ), :fedora_metadata
)

Valkyrie::StorageAdapter.register(
  Valkyrie::Storage::Fedora.new(
    connection:     ::Ldp::Client.new(Hyrax.config.fedora_connection_builder.call(
      ENV.fetch('FEDORA6_URL') { "http://localhost:8985/fcrepo/rest" }
    )),
    base_path:      ENV.fetch('FEDORA_BASE_PATH', Rails.env).gsub(/^\/|\/$/, ''),
    fedora_version: 6
  ), :fedora_storage
)

Valkyrie.config.metadata_adapter = ENV.fetch('VALKYRIE_METADATA_ADAPTER') { :fedora_metadata }.to_sym
Valkyrie.config.storage_adapter  = ENV.fetch('VALKYRIE_STORAGE_ADAPTER') { :fedora_storage }.to_sym

Rails.application.config.to_prepare do
  Valkyrie::Storage::Fedora.class_eval do
    # [Hyrax-override-valkyrie-v3.6.1] Adds `identifier_endpath` support for
    # multi-file FileSet uploads, and restores the 409-conflict retry that
    # Valkyrie 3.6.1 removed from `mint_version`.
    #
    # Fedora 6 auto-versions with per-second Memento timestamps.  When multiple
    # files are uploaded to the same FileSet within one second, the auto-version
    # may not yet be visible and the fallback `mint_version` call can collide
    # with the auto-version, producing a 409 Conflict.
    def upload(file:, original_filename:, resource:, content_type: "application/octet-stream", # rubocop:disable Metrics/ParameterLists
               resource_uri_transformer: uri_transformer, identifier_endpath: 'original', **_extra_arguments)
      identifier = resource_uri_transformer.call(resource, base_url) + "/#{identifier_endpath}"
      upload_file(fedora_uri: identifier, io: file, content_type:, original_filename:)
      version_id = current_version_id(id: valkyrie_identifier(uri: identifier)) || mint_version(identifier, latest_version(identifier))
      perform_find(id: Valkyrie::ID.new(identifier.to_s.sub(/^.+\/\//, protocol)), version_id:)
    end

    def upload_file(fedora_uri:, io:, content_type: "application/octet-stream", original_filename: "default")
      sha1 = fedora_version >= 5 ? "sha" : "sha1"
      retries = 0
      max_retries = 5

      begin
        response = connection.http.put do |request|
          request.url fedora_uri
          request.headers['Content-Type'] = content_type
          io_size = (io.length if io.respond_to?(:length)) || (io.size if io.respond_to?(:size))
          request.headers['Content-Length'] = io_size.to_s if io_size
          request.headers['Content-Disposition'] = "attachment; filename=\"#{original_filename}\""
          request.headers['digest'] = "#{sha1}=#{Digest::SHA1.file(io)}" if io.respond_to?(:to_str)
          request.headers['link'] = "<http://www.w3.org/ns/ldp#NonRDFSource>; rel=\"type\""
          io = Faraday::UploadIO.new(io, content_type, original_filename)
          request.body = io
        end

        Rails.logger.info("LDP Put Response Status: #{response.status}")
        raise Ldp::HttpError unless [201, 204].include?(response.status)
      rescue Ldp::HttpError => e
        retries += 1

        Rails.logger.error("LDP Put failed (HTTP #{e&.response&.status || '?'}). Retry #{retries}/#{max_retries}...")
        raise e unless retries < max_retries)

        sleep(5 * retries)
        retry
      end
    end
  end
end
