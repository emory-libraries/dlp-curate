module Curate
  class CollectionType < Hyrax::CollectionType
    def initialize
      super
      self.title = "Library Collection"
      self.allow_multiple_membership = false
      save
    end
  end
end
