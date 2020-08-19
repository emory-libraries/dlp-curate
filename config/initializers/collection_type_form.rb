# frozen_string_literal: true

# [Hyrax-overwrite-v3.0.0.pre.rc1] This overrides the delegation list for the form.

Hyrax::Forms::Admin::CollectionTypeForm.class_eval do
  delegate :title, :description, :brandable, :discoverable, :nestable, :sharable, :share_applies_to_new_works,
                 :require_membership, :allow_multiple_membership, :assigns_workflow,
                 :assigns_visibility, :id, :collection_type_participants, :persisted?,
                 :collections?, :admin_set?, :user_collection?, :badge_color, :deposit_only_collection,
                 to: :collection_type
end
