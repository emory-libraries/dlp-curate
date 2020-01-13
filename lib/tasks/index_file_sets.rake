# frozen_string_literal: true
namespace :curate do
  namespace :file_sets do
    desc "Perform indexing on file_sets for which mime_type is missing"
    task index_file_set: :environment do
      IndexFileSet.process
    end
  end
end
