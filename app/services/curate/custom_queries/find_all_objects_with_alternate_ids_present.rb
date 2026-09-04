# frozen_string_literal: true

module Curate
  module CustomQueries
    # Solr-based query to find all objects that still have alternate_ids populated.
    # Used by the remediation rake task to migrate alternate_ids → emory_persistent_id.
    class FindAllObjectsWithAlternateIdsPresent
      class_attribute :queries
      self.queries = [:find_all_objects_with_alternate_ids_present]

      def initialize(query_service:)
        @query_service = query_service
        @connection = Hyrax.index_adapter.connection
      end

      def find_all_objects_with_alternate_ids_present
        docs = @connection.get("select", params: { q: "alternate_ids_ssim:[* TO *]", fl: "id", rows: 1_000_000 })
        ids = docs.dig("response", "docs")&.map { |d| d["id"] } || []
        ids.filter_map do |id|
          @query_service.find_by(id:)
        rescue Valkyrie::Persistence::ObjectNotFoundError
          nil
        end
      end
    end
  end
end
