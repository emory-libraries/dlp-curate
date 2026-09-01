# frozen_string_literal: true
# Composite ActiveFedora ingest job that processes all file types for a single
# FileSet sequentially within one job. This prevents concurrent writes to the
# same Fedora 4 /files container, avoiding ModeShape NullPointerExceptions
# caused by race conditions in JCR node type validation.
#
# Mirrors the pattern established by CurateValkyrieIngestJob on the Valkyrie side.

class CurateAfIngestJob < Hyrax::ApplicationJob
  queue_as Hyrax.config.ingest_queue_name

  FATAL_LDP_PATTERNS = [
    'org.modeshape.jcr.value.binary.BinaryStoreException',
    'java.lang.NullPointerException'
  ].freeze

  retry_on(Ldp::HttpError, wait: :polynomially_longer, attempts: 5) do |_job, error|
    raise Ldp::HttpError, error.message if FATAL_LDP_PATTERNS.any? { |pattern| error.message.include?(pattern) }
    Rails.logger.error("[CurateAfIngestJob] LDP error after all retries exhausted: #{error.message}")
  end

  FILE_TYPES = {
    preservation_master_file: :preservation_master_file,
    intermediate_file:        :intermediate_file,
    service_file:             :service_file,
    extracted_text:           :extracted,
    transcript:               :transcript_file
  }.freeze

  # @param file_set [FileSet] the AF FileSet to attach files to
  # @param uploaded_file [Hyrax::UploadedFile] the uploaded file with multiple file types
  # @param user [User] the depositing user
  # @param preferred [Symbol] which file type is preferred for derivatives
  def perform(file_set, uploaded_file, user, preferred)
    actor = Hyrax::Actors::FileSetActor.new(file_set, user)

    FILE_TYPES.each do |accessor, relation|
      uploader = uploaded_file.public_send(accessor)
      next if uploader.blank?

      ingest_single_file(actor:, file: uploader, relation:, preferred:)
    end
  end

  private

    def ingest_single_file(actor:, file:, relation:, preferred:)
      io_wrapper = JobIoWrapper.create_with_varied_file_handling!(
        user: actor.user, file:, relation:, file_set: actor.file_set, preferred:
      )
      io_wrapper.ingest_file
    end
end
