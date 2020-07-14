# frozen_string_literal: true

# [Hyrax overwrite]
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

    def universal_viewer_config_url(work_presenter)
      case work_presenter.solr_document['visibility_ssi']
      when 'authenticated', 'open'
        "#{request&.base_url}/uv-emory-config-liberal.json"
      when 'emory_low'
        "#{request&.base_url}/uv-emory-config-liberal-low.json"
      else
        "#{request&.base_url}/uv-emory-config.json"
      end
    end
  end
end
