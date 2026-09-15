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
      version_id = resolve_version_id(identifier)
      perform_find(id: Valkyrie::ID.new(identifier.to_s.sub(/^.+\/\//, protocol)), version_id:)
    end

    private

    # Resolves the version ID for a freshly uploaded file in Fedora 6.
    # Fedora 6 auto-versions, so we check for the auto-created version first.
    # If the auto-version isn't yet visible (timing gap), we retry once after
    # a brief sleep. Only falls through to mint_version for Fedora 4/5.
    def resolve_version_id(identifier)
      valkyrie_id = valkyrie_identifier(uri: identifier)
      vid = current_version_id(id: valkyrie_id)
      return vid if vid

      # Fedora 6 auto-version may not be immediately visible; retry once.
      if fedora_version >= 6
        sleep(0.5)
        vid = current_version_id(id: valkyrie_id)
        return vid if vid
      end

      mint_version_with_conflict_retry(identifier, latest_version(identifier))
    end

    # Restores the 409-conflict retry removed in Valkyrie 3.6.1.
    # Fedora 6 Memento versions are timestamp-based at per-second granularity;
    # a 409 means a version already exists for this second.
    def mint_version_with_conflict_retry(identifier, version_name = "version1")
      response = connection.http.post do |request|
        request.url "#{identifier}/fcr:versions"
        request.headers['Slug'] = version_name if fedora_version == 4
      end
      return nil if response.status == 410
      if response.status == 409
        sleep(0.5)
        return mint_version_with_conflict_retry(identifier, version_name)
      end
      raise "Version unable to be created (HTTP #{response.status})" unless response.status == 201
      valkyrie_identifier(uri: response.headers["location"].gsub("/fcr:metadata", ""))
    end
  end
end
