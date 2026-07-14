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
