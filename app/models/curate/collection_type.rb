module Curate
  class CollectionType < Hyrax::CollectionType
    # If a Curate::CollectionType already exists, return it.
    # Otherwise, make a new one and return that.
    def self.find_or_create_library_collection_type
      existing_library_collection_type = Curate::CollectionType.find_by_title("Library Collection")
      return existing_library_collection_type if existing_library_collection_type
      new_library_collection_type = Curate::CollectionType.new
      new_library_collection_type.save
      new_library_collection_type
    end

    def initialize
      super
      self.title = "Library Collection"
      self.description = "Library staff-curated collections"
      self.allow_multiple_membership = false
      save
      allow_admins_to_manage
    end

    def allow_admins_to_manage
      h = Hyrax::CollectionTypeParticipant.new
      h.hyrax_collection_type_id = id
      h.agent_type = "group"
      h.agent_id = "admin"
      h.access = "manage"
      h.save
    end
  end
end
