# Generated via
#  `rails generate hyrax:work CurateGenericWork`
class CurateGenericWorkIndexer < Hyrax::WorkIndexer
  # This indexes the default metadata. You can remove it if you want to
  # provide your own metadata and indexing.
  # include Hyrax::IndexesBasicMetadata

  # Fetch remote labels for based_near. You can remove this if you don't want
  # this behavior
  # include Hyrax::IndexesLinkedMetadata

  def generate_solr_document
    super.tap do |solr_doc|
      solr_doc['preservation_workflow_terms_sim'] = preservation_workflow_terms
    end
  end

  def preservation_workflow_terms
    object.preservation_workflow.map(&:preservation_terms)
  end
end
