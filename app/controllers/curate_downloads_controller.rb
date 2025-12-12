# frozen_string_literal: true

class CurateDownloadsController < ApplicationController
  include Hydra::Controller::DownloadBehavior
  include Hyrax::LocalFileDownloadsControllerBehavior
  # All of the altered and unchanged methods have been moved to the module below so that they
  #   can be shared with CurateDownloadsController.
  include CurateDownloadsControllerBehavior
  skip_before_action :authorize_download!
  skip_before_action :authenticate_user!

  # Altered by Emory.
  def self.default_content_path
    :preservation_master_file
  end

  def pdf_for_viewer
    if file.is_a?(ActiveFedora::File) && file&.mime_type&.include?('pdf') && !file.new_record?
      send_content
    elsif file.is_a?(String) && file&.include?('pdf')
      send_local_content
    else
      raise Hyrax::ObjectNotFoundError
    end
  end

  private

    # Altered by Emory.
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
