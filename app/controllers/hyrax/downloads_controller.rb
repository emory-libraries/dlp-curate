# frozen_string_literal: true

# [Hyrax-overwrite-v3.4.2] Changes :og to :pmf as default_content and adds content_path method for
# fetching `use` for additional files
module Hyrax
  class DownloadsController < ApplicationController
    include Hydra::Controller::DownloadBehavior
    include Hyrax::LocalFileDownloadsControllerBehavior
    # All of the altered and unchanged methods have been moved to the module below so that they
    #   can be shared with CurateDownloadsController.
    include CurateDownloadsControllerBehavior
    skip_before_action :authenticate_user!

    # Altered by Emory.
    def self.default_content_path
      :preservation_master_file
    end

    # Render the 404 page if the file doesn't exist.
    # Otherwise renders the file.
    def show
      case file
      when ActiveFedora::File
        # For original files that are stored in fedora
        super
      when String
        # For derivatives stored on the local file system
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
                                   DownloadsController.default_content_path
                                 end
        association = dereference_file(default_file_reference)
        association&.reader
      end
  end
end
