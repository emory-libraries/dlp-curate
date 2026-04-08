# frozen_string_literal: true
# [Hyrax-override-v5.2.0] Adds custom characterization attributes to Hyrax::FileMetadata.
# These mirror the AF-side CurateFileSchema and AlphaChannelsSchema properties
# so that Wings/Freyja can round-trip file metadata between AF and Valkyrie.

Rails.application.config.to_prepare do
  Hyrax::FileMetadata.class_eval do
    attribute :original_checksum, ::Valkyrie::Types::Set
    attribute :file_path, ::Valkyrie::Types::Set
    attribute :creating_os, ::Valkyrie::Types::Set
    attribute :creating_application_name, ::Valkyrie::Types::Set
    attribute :puid, ::Valkyrie::Types::Set
    attribute :alpha_channels, ::Valkyrie::Types::Set
  end
end
