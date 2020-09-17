# frozen_string_literal: true
# [Hyrax-overwrite-v3.0.0.pre.rc1]
# Adds preservation event for fileset characterization

class CharacterizeJob < Hyrax::ApplicationJob
  include PreservationEvents

  queue_as Hyrax.config.ingest_queue_name

  # Characterizes the file at 'filepath' if available, otherwise, pulls a copy from the repository
  # and runs characterization on that file.
  # @param [FileSet] file_set
  # @param [String] file_id identifier for a Hydra::PCDM::File
  # @param [String, NilClass] filepath the cached file within the Hyrax.config.working_path
  def perform(file_set, file_id, filepath = nil, user = nil)
    event_start = DateTime.current
    relation = file_set.class.characterization_proxy
    file = file_set.characterization_proxy
    raise "#{relation} was not found for FileSet #{file_set.id}" unless file_set.characterization_proxy?
    filepath = Hyrax::WorkingDirectory.find_or_retrieve(file_id, file_set.id) unless filepath && File.exist?(filepath)
    Hydra::Works::CharacterizationService.run(file, filepath, {}, user)
    event = { 'type' => 'Characterization', 'start' => event_start, 'outcome' => 'Success',
              'details' => "#{relation}: #{file.file_name.first} - Technical metadata extracted from file, format identified, and file validated",
              'software_version' => 'FITS v1.5.0', 'user' => user.presence || file_set.depositor }
    create_preservation_event(file_set, event)
    Rails.logger.debug "Ran characterization on #{file.id} (#{file.mime_type})"
    file.alpha_channels = channels(filepath) if file_set.image? && Hyrax.config.iiif_image_server?
    file.save!
    file_set.update_index
    # commenting this job call since we are doing this in the file_actor
    # CreateDerivativesJob.perform_later(file_set, file_id, filepath)
  end

  private

    def channels(filepath)
      ch = MiniMagick::Tool::Identify.new do |cmd|
        cmd.format '%[channels]'
        cmd << filepath
      end
      [ch]
    end
end
