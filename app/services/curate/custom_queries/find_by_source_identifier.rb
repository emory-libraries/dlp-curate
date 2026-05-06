# frozen_string_literal: true

module Curate
  module CustomQueries
    # Solr-based implementation of find_by_model_and_property_value for Freyja adapter.
    # Used by Bulkrax::ValkyrieObjectFactory.search_by_property to locate records
    # by deduplication_key or other indexed properties.
    #
    # @example
    #   Hyrax.query_service.custom_queries.find_by_model_and_property_value(
    #     model: CurateGenericWorkResource, property: 'deduplication_key_tesim', value: 'abc123'
    #   )
    class FindBySourceIdentifier < SolrDocumentQuery
      self.queries = [:find_by_model_and_property_value]

      # @param model [Class] the Valkyrie resource class (e.g. CurateGenericWorkResource)
      # @param property [#to_s] the Solr field name to query
      # @param value [#to_s] the value to match
      #
      # @return [NilClass] when no record was found
      # @return [Valkyrie::Resource] when a record was found
      def find_by_model_and_property_value(model:, property:, value:)
        @model = model
        @property = property
        @value = value

        return if resource.blank?
        @query_service.find_by(id: resource['id'])
      end

      def query
        "has_model_ssim:#{@model} AND #{@property}:#{@value}"
      end
    end
  end
end
