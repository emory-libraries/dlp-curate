# frozen_string_literal: true

# Re-runs characterization on a FileSet's primary/original file.
# Supports both ActiveFedora and Valkyrie file sets during lazy migration.
class ReCharacterizeJob < Hyrax::ApplicationJob
  # Valkyrie FileMetadata attributes that mirror the AF CurateFileSchema and
  # are added by config/initializers/hyrax_file_metadata_override.rb. These
  # are cleared before re-characterization so stale data does not survive
  # a characterization failure mid-run.
  VALKYRIE_CUSTOM_CHARACTERIZATION_ATTRS = [
    :original_checksum,
    :file_path,
    :creating_os,
    :creating_application_name,
    :puid,
    :alpha_channels
  ].freeze

  def perform(file_set_id:, user: nil)
    file_set = load_file_set(file_set_id)

    case file_set
    when Hyrax::Resource
      perform_valkyrie(file_set, user)
    else
      perform_af(file_set, user)
    end
  end

  private

    def load_file_set(file_set_id)
      if file_set_id.length == 36
        Hyrax.query_service.find_by(id: file_set_id)
      else
        FileSet.find(file_set_id)
      end
    end

    def perform_af(file_set, user)
      repository_file = file_set.pulled_preservation_master_file

      ReCharacterizationService.empty_out_characterization(repository_file)
      CharacterizeJob.perform_later(file_set, repository_file.id, "", user)
    end

    def perform_valkyrie(file_set, _user)
      file_metadata = original_file_metadata(file_set)
      return unless file_metadata

      empty_valkyrie_characterization(file_metadata)
      ValkyrieCharacterizationJob.perform_later(file_metadata.id.to_s)
    end

    # Finds the Hyrax::FileMetadata flagged as ORIGINAL_FILE (equivalent to
    # AF's preservation_master_file) on the FileSetResource.
    def original_file_metadata(file_set)
      Hyrax.custom_queries
           .find_many_file_metadata_by_use(resource: file_set, use: Hyrax::FileMetadata::Use::ORIGINAL_FILE)
           .first
    end

    # Valkyrie counterpart to ReCharacterizationService.empty_out_characterization.
    # Clears the custom dlp-curate characterization attributes on the FileMetadata
    # so they are repopulated by ValkyrieCharacterizationJob.
    def empty_valkyrie_characterization(file_metadata)
      VALKYRIE_CUSTOM_CHARACTERIZATION_ATTRS.each do |attr|
        file_metadata.public_send("#{attr}=", []) if file_metadata.respond_to?("#{attr}=")
      end
      Hyrax.persister.save(resource: file_metadata)
    end
end
