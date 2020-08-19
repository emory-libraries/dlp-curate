# frozen_string_literal: true

# [Hyrax-overwrite-v3.0.0.pre.rc1] This only changes the allowed params for the
# CollectionTypes Controller.
Hyrax::Admin::CollectionTypesController.class_eval do
  private

    def collection_type_params
      params.require(:collection_type).permit(
        :title, :description, :nestable, :brandable, :discoverable, :sharable,
        :share_applies_to_new_works, :allow_multiple_membership, :require_membership,
        :assigns_workflow, :assigns_visibility, :badge_color, :deposit_only_collection
      )
    end
end
