namespace :curate do
  namespace :collections do
    desc 'Langmuir collection setup'
    task langmuir_setup: [:environment] do
      Rake::Task["hyrax:default_admin_set:create"].invoke
      Rake::Task["hyrax:default_collection_types:create"].invoke
      Rake::Task["curate:create_library_collection_type"].invoke
      Rake::Task["hyrax:workflow:load"].invoke
      langmuir_csv_file = Rails.root.join('config', 'collection_metadata', 'langmuir_collection.csv')
      CurateCollectionImporter.new.import(langmuir_csv_file)
      puts "Langmuir collection object created"
    end
  end
end
