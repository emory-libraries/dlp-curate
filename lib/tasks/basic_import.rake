# frozen_string_literal: true

# Set these values on the command line when you invoke the rake task.
# CSV_FILE should point to the csv you want to import, and
# IMPORT_FILE_PATH should point to a directory containing the files to be attached.
CSV_FILE = ENV['CSV_FILE']
IMPORT_FILE_PATH = ENV['IMPORT_FILE_PATH']

namespace :curate do
  namespace :basic_import do
    desc 'Ingest sample data'
    task sample: [:environment] do
      Rake::Task["hyrax:default_admin_set:create"].invoke
      Rake::Task["hyrax:default_collection_types:create"].invoke
      Rake::Task["hyrax:workflow:load"].invoke
      csv_file = Rails.root.join('spec', 'fixtures', 'csv_import', 'zizia_basic.csv')
      ModularImporter.new(csv_file).import
    end
  end
end
