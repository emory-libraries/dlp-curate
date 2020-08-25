# frozen_string_literal: true

# [Hyrax-overwrite-v3.0.0.pre.rc1] Adds source collection search facet to works page
Hyrax::My::WorksController.class_eval do
  # Define collection specific filter facets.
  def self.configure_facets
    configure_blacklight do |config|
      config.add_facet_field "source_collection_title_ssim", limit: 5, label: 'Source Collection'
    end
  end
  configure_facets
end
