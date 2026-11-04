# frozen_string_literal: true

module Curate
  module CustomQueries
    # Provides a `find_parent_works` (plural) query that wraps Hyrax's built-in
    # `find_parent_work` (singular) navigator and returns results as an array,
    # matching the interface expected by CurateGenericWorkResourceIndexer.
    class FindParentWorks
      def self.queries
        [:find_parent_works]
      end

      attr_reader :query_service

      def initialize(query_service:)
        @query_service = query_service
      end

      # @param resource [Valkyrie::Resource]
      # @return [Array<Valkyrie::Resource>]
      def find_parent_works(resource:)
        result = Hyrax.custom_queries.find_parent_work(resource:)
        result ? [result] : []
      end
    end
  end
end
