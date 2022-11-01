# frozen_string_literal: true
# [Hyrax-overwrite-v3.4.2] - Adds logger info and warning for bad/missing tmp files L#13-L#20

class CreateDerivativesJob < Hyrax::ApplicationJob
  queue_as :derivatives

  # @param [FileSet] file_set
  # @param [String] file_id identifier for a Hydra::PCDM::File
  # @param [String, NilClass] filepath the cached file within the Hyrax.config.working_path
  def perform(file_set, file_id, filepath = nil)
    return if file_set.video? && !Hyrax.config.enable_ffmpeg
    filename = Hyrax::WorkingDirectory.find_or_retrieve(file_id, file_set.id, filepath)
    @logger = Logger.new(STDOUT)
    @logger.info "CreateDerivativesJob for #{filename} started at #{DateTime.current}"

    begin
      file_set.create_derivatives(filename)
    rescue
      @logger.warn "Error occurred in CreateDerivativesJob for #{filename}"
    end

    # Reload from Fedora and reindex for thumbnail and extracted text
    file_set.reload
    file_set.update_index
    file_set.parent.update_index if parent_needs_reindex?(file_set)
  end

  # If this file_set is the thumbnail for the parent work,
  # then the parent also needs to be reindexed.
  def parent_needs_reindex?(file_set)
    return false unless file_set.parent
    file_set.parent.thumbnail_id == file_set.id
  end
end
