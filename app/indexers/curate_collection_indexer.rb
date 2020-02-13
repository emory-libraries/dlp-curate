# frozen_string_literal: true

class CurateCollectionIndexer < Hyrax::CollectionIndexer
  def rdf_service
    CurateIndexer
  end

  def generate_solr_document
    super.tap do |solr_doc|
      solr_doc['member_works_count_isi'] = object.child_works.count
    end
  end
end
