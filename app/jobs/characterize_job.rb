# frozen_string_literal: true
# [Hyrax-overwrite-v3.4.2]

##
# a +ActiveJob+ job to process file characterization.
#
# the characterization process is handled by a service object, which is
# configurable via {CharacterizeJob.characterization_service}.
#
# @example setting a custom characterization service
#   class MyCharacterizer
#     def run(file, path)
#       # do custom characterization
#     end
#   end
#
#   # in a Rails initializer
#   CharacterizeJob.characterization_service = MyCharacterizer.new
# end
# Override: Adds preservation event for fileset characterization

class CharacterizeJob < Hyrax::ApplicationJob
  include PreservationEvents

  queue_as Hyrax.config.ingest_queue_name

  class_attribute :characterization_service
  self.characterization_service = Hydra::Works::CharacterizationService

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
    characterize(
      file:        file,
      filepath:    filepath,
      user:        user,
      event_start: event_start,
      relation:    relation,
      file_set:    file_set
    )
  end

  private

    def characterize(file:, filepath: nil, user: nil, event_start:, relation:, file_set:)
      # store this so we can tell if the original_file is actually changing
      previous_checksum = file.original_checksum.first

      clear_metadata(file_set)

      characterization_service.run(file, filepath, {}, user)
      Rails.logger.debug "Ran characterization on #{file.id} (#{file.mime_type})"
      file.alpha_channels = channels(filepath) if file_set.image? && Hyrax.config.iiif_image_server?
      file.save!

      # Ensure that if the actual file content has changed, the mod timestamp on the FileSet object changes.
      # Otherwise this does not happen when rolling back to a previous version. Perhaps this should be set as part of...
      # `FileActor.revert_to` (or its replacement Transaction?!), where the FileSet is saved. Not sure if the...
      # before/after checksum is readily available there though. I like this checksum verification because it allows...
      # all changes to the current FileSet version to be detected, which in our case triggers re-creation of a...
      # "cold storage" archive of the parent Work. It's worth noting that adding a *new* version always touches this...
      # mod time. This is done in the versioning code.
      file_set.date_modified = Hyrax::TimeService.time_in_utc if file.original_checksum.first != previous_checksum

      file_set.save!
      file_set.update_index
      # commenting this job call since we are doing this in the file_actor
      # CreateDerivativesJob.perform_later(file_set, file_id, filepath)
      process_preservation_event(file_set, event_start, relation, file, user)
    end

    def clear_metadata(file_set)
      # The characterization of additional file versions adds new height/width/size/checksum values to un-orderable...
      # `ActiveTriples::Relation` fields on `original_file`. Values from those are then randomly pulled into Solr...
      # fields which may have scalar or vector cardinality. So for height/width you get two scalar values pulled from...
      # "randomized parallel arrays". Upshot is to reset all of these before (re)characterization to stop the mayhem.
      file_set.characterization_proxy.height = []
      file_set.characterization_proxy.width  = []
      file_set.characterization_proxy.original_checksum = []
      file_set.characterization_proxy.file_size = []
      file_set.characterization_proxy.format_label = []
    end

    def channels(filepath)
      ch = MiniMagick::Tool::Identify.new do |cmd|
        cmd.format '%[channels]'
        cmd << filepath
      end
      [ch]
    end

    ##
    # @api public
    # @return [#run]
    def characterization_service
      self.class.characterization_service
    end

    def pres_event_details(metadata_populated, relation, file)
      return "#{relation}: #{file.file_name.first} - Technical metadata extracted from file, format identified, and file validated" if metadata_populated
      "The Characterization Service failed."
    end

    def process_preservation_event(file_set, event_start, relation, file, user)
      metadata_populated = check_for_populated_metadata(file_set)
      event = {
        'type' => 'Characterization',
        'start' => event_start,
        'outcome' => metadata_populated ? 'Success' : 'Failure',
        'details' => pres_event_details(metadata_populated, relation, file),
        'software_version' => 'FITS v1.5.0',
        'user' => user.presence || file_set.depositor
      }
      create_preservation_event(file_set, event)
    end

    def check_for_populated_metadata(file_set)
      ['height', 'width', 'original_checksum', 'file_size', 'format_label'].any? { |v| file_set.characterization_proxy.send(v).present? }
    end
end
