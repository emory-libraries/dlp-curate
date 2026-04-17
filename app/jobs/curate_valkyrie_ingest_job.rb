# frozen_string_literal: true
# [Hyrax-override-v5.2.0] Custom ingest job for dlp-curate's multi-file-per-FileSet pattern.
# Unlike stock ValkyrieIngestJob (which handles a single file per UploadedFile),
# this job uploads all file types present on a Hyrax::UploadedFile
# (preservation_master, intermediate, service, extracted_text, transcript)
# as separate Hyrax::FileMetadata records with the correct pcdm_use.
#
# Characterization is triggered only for ORIGINAL_FILE (preservation_master) via
# Hyrax::Listeners::FileListener#on_file_uploaded, matching the AF-side behavior
# in config/initializers/file_actor.rb.

class CurateValkyrieIngestJob < Hyrax::ApplicationJob
  queue_as Hyrax.config.ingest_queue_name

  FILE_TYPE_TO_USE = {
    preservation_master_file: Hyrax::FileMetadata::Use::ORIGINAL_FILE,
    intermediate_file:        Hyrax::FileMetadata::Use::INTERMEDIATE_FILE,
    service_file:             Hyrax::FileMetadata::Use::SERVICE_FILE,
    extracted_text:           Hyrax::FileMetadata::Use::EXTRACTED_TEXT,
    transcript:               Hyrax::FileMetadata::Use::TRANSCRIPT
  }.freeze

  def perform(uploaded_file)
    file_set = Hyrax.query_service.find_by(id: Valkyrie::ID.new(uploaded_file.file_set_uri))
    preferred = determine_preferred(uploaded_file)

    FILE_TYPE_TO_USE.each do |file_type, pcdm_use|
      uploader = uploaded_file.public_send(file_type)
      next if uploader.blank?

      skip_derivs = file_type != preferred
      upload_single_file(uploaded_file:, file_set:, uploader:, pcdm_use:, skip_derivatives: skip_derivs)
    end
  end

  private

    def determine_preferred(uploaded_file)
      if uploaded_file.service_file.present?
        :service_file
      elsif uploaded_file.intermediate_file.present?
        :intermediate_file
      else
        :preservation_master_file
      end
    end

    def upload_single_file(uploaded_file:, file_set:, uploader:, pcdm_use:, skip_derivatives:)
      carrier_wave_file = uploader.file
      file_io = carrier_wave_file.to_file

      ::Hyrax::ValkyrieUpload.file(
        io:               file_io,
        filename:         carrier_wave_file.original_filename,
        file_set:,
        use:              pcdm_use,
        user:             uploaded_file.user,
        skip_derivatives:
      )
    end
end
