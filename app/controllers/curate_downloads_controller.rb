# frozen_string_literal: true
# [Hyrax-override-hyrax-v5.2.0] Custom downloads controller for PDF viewer and file downloads.
# Supports both ActiveFedora and Valkyrie file sets during the lazy migration.

class CurateDownloadsController < ApplicationController
  include Hydra::Controller::DownloadBehavior
  include Hyrax::LocalFileDownloadsControllerBehavior
  include CurateDownloadsControllerBehavior
  include Hyrax::ValkyrieDownloadsControllerBehavior
  skip_before_action :authorize_download!
  skip_before_action :authenticate_user!

  def self.default_content_path
    :preservation_master_file
  end

  def pdf_for_viewer
    if Hyrax.config.use_valkyrie?
      pdf_for_viewer_valkyrie
    else
      pdf_for_viewer_af
    end
  end

  private

    def pdf_for_viewer_af
      if file.is_a?(ActiveFedora::File) && file&.mime_type&.include?('pdf') && !file.new_record?
        send_content
      elsif file.is_a?(String) && file&.include?('pdf')
        send_local_content
      else
        raise Hyrax::ObjectNotFoundError
      end
    end

    def pdf_for_viewer_valkyrie
      file_set = Hyrax.query_service.find_by(id: params[:id])
      file_metadata = Hyrax.custom_queries
                           .find_many_file_metadata_by_use(resource: file_set,
                                                           use:      Hyrax::FileMetadata::Use::ORIGINAL_FILE)
                           .find { |fm| fm.mime_type&.include?('pdf') }
      raise Hyrax::ObjectNotFoundError unless file_metadata

      send_file_contents_valkyrie(file_set)
    end

    def default_file
      default_file_reference = if asset.class.respond_to?(:default_file_path)
                                 asset.class.default_file_path
                               elsif content_path
                                 content_path
                               else
                                 CurateDownloadsController.default_content_path
                               end
      association = dereference_file(default_file_reference)
      association&.reader || alternate_file_lookup(default_file_reference, asset)
    end
end
