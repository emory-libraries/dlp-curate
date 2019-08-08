module Curate
  class CollectionType < Hyrax::CollectionType
    def self.find_or_create_library_collection_type
      Curate::CollectionType.find_by_title("Library Collection") || Curate::CollectionType.new.save
    end

    def initialize
      super
      self.title = "Library Collection"
      self.allow_multiple_membership = false
      save
    end
  end
end
