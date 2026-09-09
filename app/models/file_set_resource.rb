# frozen_string_literal: true

class FileSetResource < Hyrax::FileSet
  PRIMARY = 'Primary Content'
  SUPPLEMENTAL = 'Supplemental Content'
  PRESERVATION = 'Supplemental Preservation'
  include Hyrax::Schema(:emory_file_set_metadata)
  include PreservationEvents
  Hyrax::ValkyrieLazyMigration.migrating(self, from: FileSet) if Hyrax.config.valkyrie_transition?

  attribute :preservation_event, SafePreservationEventType::TYPE

  # @return [Hyrax::FileMetadata, nil]
  def preservation_master_file
    original_file
  end

  # @return [Hyrax::FileMetadata, nil]
  def intermediate_file
    Hyrax.custom_queries.find_intermediate_file(file_set: self)
  rescue Valkyrie::Persistence::ObjectNotFoundError
    nil
  end

  # @return [Hyrax::FileMetadata, nil]
  def service_file
    Hyrax.custom_queries.find_service_file(file_set: self)
  rescue Valkyrie::Persistence::ObjectNotFoundError
    nil
  end

  # @return [Hyrax::FileMetadata, nil]
  def transcript_file
    Hyrax.custom_queries.find_transcript_file(file_set: self)
  rescue Valkyrie::Persistence::ObjectNotFoundError
    nil
  end

  def preferred_file
    if service_file.present?
      :service_file
    elsif intermediate_file.present?
      :intermediate_file
    else
      :preservation_master_file
    end
  end
end
