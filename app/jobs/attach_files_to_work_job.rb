# frozen_string_literal: true
# [Hyrax-override-hyrax-v5.2.0] Attaching multiple files to single fileset. Converts UploadedFiles into FileSets and attaches them to works.
# Supports both ActiveFedora works and Valkyrie resources during the lazy migration.

class AttachFilesToWorkJob < Hyrax::ApplicationJob
  include AttachFilesToWork
  queue_as Hyrax.config.ingest_queue_name

  # @param [ActiveFedora::Base, Hyrax::Work] work - the work object (AF or Valkyrie)
  # @param [Array<Hyrax::UploadedFile>] uploaded_files - an array of files to attach
  def perform(work, uploaded_files, **work_attributes)
    if work.is_a?(Hyrax::Resource)
      perform_valkyrie(work, uploaded_files, work_attributes)
    else
      perform_af(work, uploaded_files, work_attributes)
    end
  end
end
