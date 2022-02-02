# frozen_string_literal: true

# [Hyrax-overwrite-v3.1.0] overrides the initialize method to use the
# MultiLevelCollectionMemberSearchBuilder.
Hyrax::Collections::CollectionMemberService.class_eval do
  def initialize(scope:, collection:, params:, user_params: nil, current_ability: nil, search_builder_class: Hyrax::MultiLevelCollectionMemberSearchBuilder)
    super(
      config:               scope.blacklight_config,
      user_params:          user_params || params,
      collection:           collection,
      scope:                scope,
      current_ability:      current_ability || scope.current_ability,
      search_builder_class: search_builder_class
    )
  end
end
