# frozen_string_literal: true

class CurateCollectionIndexer < Hyrax::CollectionIndexer
  def rdf_service
    CurateIndexer
  end
end
