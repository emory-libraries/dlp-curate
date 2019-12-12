# frozen_string_literal: true

namespace :curate do
  namespace :collections do
    desc 'Make migration collections'
    task migration_setup: [:environment] do
      collection_pre_reqs
      collections_csv_file = Rails.root.join('config', 'collection_metadata', 'collections.csv')
      CurateCollectionImporter.new.import(collections_csv_file)
    end

    def collection_pre_reqs
      Rake::Task["hyrax:default_admin_set:create"].invoke
      Rake::Task["hyrax:default_collection_types:create"].invoke
      Rake::Task["curate:create_library_collection_type"].invoke
      Rake::Task["hyrax:workflow:load"].invoke
    end
  end
end
