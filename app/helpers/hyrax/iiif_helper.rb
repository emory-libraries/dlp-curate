# frozen_string_literal: true

# [Hyrax overwrite v3.4.1]
# Adds additional methods to configure UV

module Hyrax
  module IiifHelper
    def iiif_viewer_display(work_presenter, locals = {})
      render iiif_viewer_display_partial(work_presenter),
             locals.merge(presenter: work_presenter)
    end

    def iiif_viewer_display_partial(work_presenter)
      'hyrax/base/iiif_viewers/' + work_presenter.iiif_viewer.to_s
    end

    def universal_viewer_base_url
      "#{request&.base_url}/uv/uv.html"
    end

    def universal_viewer_config_url(id)
      "#{request&.base_url}/uv/config/#{id}"
    end

    def universal_viewer_manifest_link_for_work_id(id)
      "#{request&.base_url}/concern/curate_generic_works/#{id}/manifest"
    end
  end
end
