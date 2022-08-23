# frozen_string_literal: true

# [Hyrax-overwrite-v3.4.1] Adds source collection search facet to works page
# Change below was necessary to institute Source/Deposit Collection structure.
# For more information, read the SOURCE_DEPOSIT_CHANGES_README.md in dlp-curate's root folder.
Hyrax::My::WorksController.class_eval do
  # Define collection specific filter facets.
  def self.configure_facets
    configure_blacklight do |config|
      config.add_facet_field "source_collection_title_ssim", limit: 5, label: 'Source Collection'
    end
  end
  configure_facets
end
