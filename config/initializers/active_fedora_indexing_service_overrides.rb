# frozen_string_literal: true

# [ActiveFedora-overwrite-v13.3.0] rescues errors that indicate no connection to Fedora.
ActiveFedora::IndexingService.class_eval do
  # Creates a solr document hash for the {#object}
  # @yield [Hash] yields the solr document
  # @return [Hash] the solr document
  def generate_solr_document
    solr_doc = {}
    ActiveFedora.index_field_mapper.set_field(solr_doc, 'system_create', c_time, :stored_sortable)
    ActiveFedora.index_field_mapper.set_field(solr_doc, 'system_modified', m_time, :stored_sortable)
    solr_doc[ActiveFedora::QueryResultBuilder::HAS_MODEL_SOLR_FIELD] = object.has_model
    solr_doc[ActiveFedora.id_field.to_sym] = object.id
    object.declared_attached_files.each do |name, file|
      solr_doc.merge! file.to_solr(solr_doc, name: name.to_s)
    end
    solr_doc = solrize_rdf_assertions(solr_doc)
    yield(solr_doc) if block_given?
    solr_doc
  rescue Faraday::ConnectionFailed => error
    Rails.logger.error error.message
    {}
  end
end
