# frozen_string_literal: true

# Change below was necessary to institute Source/Deposit Collection structure.
# For more information, read the SOURCE_DEPOSIT_CHANGES_README.md in dlp-curate's root folder.
module Hyrax
  module Admin
    module CollectionTypesControllerOverride
      # [Hyrax-overwrite-hyrax-v5.1.0] Adding deposit_only collection to the
      # permitted params.
      def collection_type_params
        params.require(:collection_type).permit(
          :title, :description, :nestable, :brandable, :discoverable, :sharable,
          :share_applies_to_new_works, :allow_multiple_membership, :require_membership,
          :assigns_workflow, :assigns_visibility, :badge_color, :deposit_only_collection
        )
      end
    end
  end
end
