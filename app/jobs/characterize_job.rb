# [Hyrax-overwrite]
# Adds preservation event for fileset characterization

class CharacterizeJob < Hyrax::ApplicationJob
  include PreservationEvents

  queue_as Hyrax.config.ingest_queue_name

  # Characterizes the file at 'filepath' if available, otherwise, pulls a copy from the repository
  # and runs characterization on that file.
  # @param [FileSet] file_set
  # @param [String] file_id identifier for a Hydra::PCDM::File
  # @param [String, NilClass] filepath the cached file within the Hyrax.config.working_path
  def perform(file_set, file_id, filepath = nil)
    event_start = DateTime.current
    raise "#{file_set.class.characterization_proxy} was not found for FileSet #{file_set.id}" unless file_set.characterization_proxy?
    filepath = Hyrax::WorkingDirectory.find_or_retrieve(file_id, file_set.id) unless filepath && File.exist?(filepath)
    Hydra::Works::CharacterizationService.run(file_set.characterization_proxy, filepath)
    event = {
      'type' => 'Characterization', 'start' => event_start, 'outcome' => 'Success',
      'details' => 'Metadata extracted, format identified, and files validated', 'software_version' => 'Curate v.1', 'user' => file_set.depositor
    }
    create_preservation_event(file_set, event)
    Rails.logger.debug "Ran characterization on #{file_set.characterization_proxy.id} (#{file_set.characterization_proxy.mime_type})"
    file_set.characterization_proxy.save!
    file_set.update_index
    file_set.parent&.in_collections&.each(&:update_index)
  end
end
