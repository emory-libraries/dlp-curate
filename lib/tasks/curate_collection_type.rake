# frozen_string_literal: true

namespace :curate do
  desc 'Ensure CollectionType "Library Collection" exists'
  task create_library_collection_type: [:environment] do
    Curate::CollectionType.find_or_create_library_collection_type
  end
end
