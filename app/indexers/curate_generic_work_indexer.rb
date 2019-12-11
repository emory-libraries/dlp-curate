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
      solr_doc['human_readable_content_type_tesim'] = [human_readable_content_type]
      solr_doc['human_readable_rights_statement_tesim'] = [human_readable_rights_statement]
      solr_doc['human_readable_re_use_license_tesim'] = [human_readable_re_use_license]
    end
  end

  def preservation_workflow_terms
    object.preservation_workflow.map(&:preservation_terms)
  end

  def human_readable_content_type
    return unless object.content_type
    FormatLabelService.instance.label(uri: object.content_type)
  end

  def human_readable_rights_statement
    return unless object.rights_statement
    FormatLabelService.instance.label(uri: object.rights_statement)
  end

  def human_readable_re_use_license
    return unless object.re_use_license
    FormatLabelService.instance.label(uri: object.re_use_license)
  end
end
