# frozen_string_literal: true

module SolrHelpers
  def delete_all_documents_from_solr
    solr = Blacklight.default_index.connection
    solr.delete_by_query('*:*')
    solr.commit
  end

  RSpec.configure do |config|
    config.include SolrHelpers
  end
end
