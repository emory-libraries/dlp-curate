# frozen_string_literal: true

# [Hyrax-overwrite-hyrax-v5.1.0] Adds new field to delegation.
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
                 :persisted?, :admin_set?, :user_collection?, :badge_color, :deposit_only_collection,
                 to: :collection_type

        ##
        # @return [Boolean]
        def all_settings_disabled?
          collections? || admin_set? || user_collection?
        end

        ##
        # @return [Boolean]
        def share_options_disabled?
          all_settings_disabled? || !sharable
        end

        ##
        # @return [Boolean]
        def collections?
          collection_type.collections.any?
        end
      end
    end
  end
end
