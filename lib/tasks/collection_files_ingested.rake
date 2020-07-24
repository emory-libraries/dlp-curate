# frozen_string_literal: true
namespace :curate do
  namespace :collection_files_ingested do
    desc 'Process delivery of ingested files count json file'
    # If passing along multiple ids, they must be separated by one space each.
    task process: :environment do
      collection_array = ENV['collections']&.split(' ')

      CollectionFilesIngestedJob.perform_later(collection_array)
      puts 'Collection(s) files metrics have been delivered to the config/emory folder.'
    end
  end
end
