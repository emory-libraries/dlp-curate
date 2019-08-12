namespace :curate do
  namespace :collections do
    desc 'Make migration collections'
    task migration_setup: [:environment] do
      collection_pre_reqs
      Rake::Task["curate:collections:langmuir_setup"].invoke
      Rake::Task["curate:collections:yearbooks_setup"].invoke
      Rake::Task["curate:collections:yellowbacks_setup"].invoke
    end

    desc 'Langmuir collection setup'
    task langmuir_setup: [:environment] do
      collection_pre_reqs
      langmuir_csv_file = Rails.root.join('config', 'collection_metadata', 'langmuir_collection.csv')
      CurateCollectionImporter.new.import(langmuir_csv_file)
      puts "Langmuir collection object created"
    end

    desc 'Yearbooks collection setup'
    task yearbooks_setup: [:environment] do
      collection_pre_reqs
      yearbooks_csv_file = Rails.root.join('config', 'collection_metadata', 'yearbooks_collection.csv')
      CurateCollectionImporter.new.import(yearbooks_csv_file)
      puts "Yearbooks collection object created"
    end

    desc 'Yellowbacks collection setup'
    task yellowbacks_setup: [:environment] do
      collection_pre_reqs
      yellowbacks_csv_file = Rails.root.join('config', 'collection_metadata', 'yellowbacks_collection.csv')
      CurateCollectionImporter.new.import(yellowbacks_csv_file)
      puts "Yellowbacks collection object created"
    end

    def collection_pre_reqs
      Rake::Task["hyrax:default_admin_set:create"].invoke
      Rake::Task["hyrax:default_collection_types:create"].invoke
      Rake::Task["curate:create_library_collection_type"].invoke
      Rake::Task["hyrax:workflow:load"].invoke
    end
  end
end
