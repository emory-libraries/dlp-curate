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
    def upload(file:, original_filename:, resource:, content_type: "application/octet-stream", # rubocop:disable Metrics/ParameterLists
               resource_uri_transformer: uri_transformer, identifier_endpath: 'original', **_extra_arguments)
      identifier = resource_uri_transformer.call(resource, base_url) + "/#{identifier_endpath}"
      upload_file(fedora_uri: identifier, io: file, content_type:, original_filename:)
      # Fedora 6 auto versions, so check to see if there's a version for this
      # initial upload. If not, then mint one (fedora 4/5)
      version_id = current_version_id(id: valkyrie_identifier(uri: identifier)) || mint_version(identifier, latest_version(identifier))
      perform_find(id: Valkyrie::ID.new(identifier.to_s.sub(/^.+\/\//, protocol)), version_id:)
    end
  end
end
