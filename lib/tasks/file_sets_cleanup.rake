# frozen_string_literal: true
namespace :curate do
  namespace :file_sets do
    desc "Perform indexing on file_sets for which mime_type is missing"
    task file_sets_cleanup: :environment do
      FileSetCleanUpJob.perform_later
    end
  end
end
