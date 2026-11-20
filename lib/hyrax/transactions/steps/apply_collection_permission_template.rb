# frozen_string_literal: true

module Hyrax
  module Transactions
    module Steps
      ##
      # A step that gives a new work the sharing of the collection it is deposited in,
      # as the AF ApplyPermissionTemplateActor does for a single collection whose type
      # shares with new works. Hyrax's apply_permission_template step only applies the
      # admin set's sharing. Runs before work_resource.save_acl, which saves the grants.
      class ApplyCollectionPermissionTemplate
        include Dry::Monads[:result]

        def call(object)
          Curate::CollectionSharingService.apply(object)
          Success(object)
        rescue StandardError => e
          Failure["Failed to apply the collection's sharing: #{e.message}", object]
        end
      end
    end
  end
end
