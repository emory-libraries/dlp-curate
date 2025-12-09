# frozen_string_literal: true

class CurateDownloadsController < ApplicationController
  include Hydra::Controller::DownloadBehavior
  include Hyrax::LocalFileDownloadsControllerBehavior
  # All of the altered and unchanged methods have been moved to the module below so that they
  #   can be shared with CurateDownloadsController.
  include CurateDownloadsControllerBehavior
  skip_before_action :authorize_download!
  skip_before_action :authenticate_user!

  def pdf_for_viewer
    if file.is_a?(ActiveFedora::File) && file&.mime_type&.include?('pdf') && !file.new_record?
      send_content
    elsif file.is_a?(String) && file&.include?('pdf')
      send_local_content
    else
      raise Hyrax::ObjectNotFoundError
    end
  end
end
