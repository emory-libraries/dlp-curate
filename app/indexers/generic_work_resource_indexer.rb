# frozen_string_literal: true

class GenericWorkResourceIndexer < Hyrax::Indexers::PcdmObjectIndexer(GenericWorkResource)
  include Hyrax::Indexer(:emory_basic_metadata)
  include Hyrax::Indexer(:generic_work_resource)
end
