# frozen_string_literal: true

module Curate
  module CustomQueries
    class SolrDocumentQuery
      def initialize(query_service:)
        @query_service = query_service
        @connection = Hyrax.index_adapter.connection
      end

      class_attribute :queries
      attr_reader :query_service

      def resource
        @connection.get("select", params: { q: query, fl: "*", rows: 1 })["response"]["docs"].first
      end
    end
  end
end
