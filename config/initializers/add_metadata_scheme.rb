# frozen_string_literal: true

ActiveFedora::WithMetadata::DefaultMetadataClassFactory.file_metadata_schemas += [
  Schemas::CurateFileSchema
]
