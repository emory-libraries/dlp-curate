# frozen_string_literal: true

# Note: Hyrax::CollectionType was updated in our recent version v3.1.0. However,
# the updates do not affect any of our actions below. The changes were largely refactors
# and the overall behavior of this model remains intact. Hyrax::CollectionTypeParticipant
# was also examined and deemed to not have any alterations that would affect us.gst
module Curate
  class CollectionType < Hyrax::CollectionType
    after_initialize :configure
    USER_COLLECTION_DEFAULT_TITLE = 'Library Collection'

    # If a Curate::CollectionType already exists, ensure it adheres to expectations and return it.
    # Otherwise, make a new one and return that.
    def self.find_or_create_library_collection_type
      existing_library_collection_type = Curate::CollectionType.find_by_title("Library Collection")
      if existing_library_collection_type
        existing_library_collection_type.configure
        return existing_library_collection_type
      end
      new_library_collection_type = Curate::CollectionType.new
      new_library_collection_type
    end

    def configure
      self.title = "Library Collection"
      self.description = "Library staff curated collections"
      self.allow_multiple_membership = false
      save
      remove_all_participants
      allow_admins_to_manage
    end

    # Remove all participants from the collection type and only add back in admins
    def remove_all_participants
      Hyrax::CollectionTypeParticipant.where(hyrax_collection_type_id: id).all.find_each(&:destroy!)
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
