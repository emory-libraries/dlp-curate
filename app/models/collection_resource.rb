# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:collection_resource CollectionResource`
class CollectionResource < Hyrax::PcdmCollection
  include Hyrax::Schema(:emory_basic_metadata)
  include Hyrax::Schema(:collection_resource)
  Hyrax::ValkyrieLazyMigration.migrating(self, from: Collection) if Hyrax.config.valkyrie_transition?
end
