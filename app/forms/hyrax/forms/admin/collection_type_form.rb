# frozen_string_literal: true

# [Hyrax-overwrite-v3.0.0.pre.rc1] Adds new field to delegation.
module Hyrax
  module Forms
    module Admin
      class CollectionTypeForm
        include ActiveModel::Model
        attr_accessor :collection_type
        validates :title, presence: true

        # Change below was necessary to institute Source/Deposit Collection structure.
        # For more information, read the SOURCE_DEPOSIT_CHANGES_README.md in dlp-curate's root folder.
        delegate :title, :description, :brandable, :discoverable, :nestable, :sharable,
                 :share_applies_to_new_works, :require_membership, :allow_multiple_membership,
                 :assigns_workflow, :assigns_visibility, :id, :collection_type_participants,
                 :persisted?, :collections?, :admin_set?, :user_collection?, :badge_color,
                 :deposit_only_collection,
                 to: :collection_type

        def all_settings_disabled?
          collections? || admin_set? || user_collection?
        end

        def share_options_disabled?
          all_settings_disabled? || !sharable
        end
      end
    end
  end
end
