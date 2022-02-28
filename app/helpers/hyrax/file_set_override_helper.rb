# frozen_string_literal: true
module Hyrax::FileSetOverrideHelper
  include Hyrax::FileSetHelper

  ##
  # @todo inline the "workflow restriction" into the `can?(:download)` check.
  #
  # @param file_set [#id]
  #
  # @return [Boolean] whether to display the download link for the given file
  #   set. This is a [Hyrax-overwrite-v3.3.0] that corrects a bug created by omitting
  #   the id call on the file_set in the can? verification.
  def display_media_download_link?(file_set:)
    Hyrax.config.display_media_download_link? &&
      can?(:download, file_set.id) &&
      !workflow_restriction?(file_set.try(:parent))
  end
end
