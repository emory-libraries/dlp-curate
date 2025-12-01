# frozen_string_literal: true

# [Hyrax-overwrite-hyrax-v5.2.0] Changes :og to :pmf as default_content and adds content_path method for
# fetching `use` for additional files
module Hyrax
  class DownloadsController < ApplicationController
    include Hydra::Controller::DownloadBehavior
    include Hyrax::StreamFileDownloadsControllerBehavior
    include Hyrax::LocalFileDownloadsControllerBehavior
    # All of the altered and unchanged methods have been moved to the module below so that they
    #   can be shared with CurateDownloadsController.
    include CurateDownloadsControllerBehavior
    include Hyrax::ValkyrieDownloadsControllerBehavior
    include Hyrax::WorkflowsHelper # Provides #workflow_restriction?
    skip_before_action :authenticate_user!

    # Altered by Emory.
    def self.default_content_path
      :preservation_master_file
    end

    # Render the 404 page if the file doesn't exist.
    # Otherwise renders the file.
    def show
      # We will use the thumbnail from our file system first, if one exists
      # Otherwise we will fallback to Valkyrie, then the default implementations
      use = params.fetch(:file, :original_file).to_sym
      if use == :thumbnail
        thumbnail = Hyrax::DerivativePath.derivative_path_for_reference(params[:id], 'thumbnail')
        if thumbnail.present? && File.exist?(thumbnail)
          @file = thumbnail
          return send_local_content
        end
      end

      return show_valkyrie if Hyrax.config.use_valkyrie?

      show_active_fedora
    end

    private

    def show_active_fedora
      case file
      when ActiveFedora::File
        # For original files that are stored in fedora
        hydra_show_active_fedora_file
      when String
        # For derivatives stored on the local file system
        send_local_content
      else
        raise Hyrax::ObjectNotFoundError
      end
    end

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
      association&.reader || alternate_file_lookup(default_file_reference, asset)
    end
  end
end
