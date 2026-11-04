# frozen_string_literal: true

module Curate
  module CustomQueries
    # Solr-based lookup by emory_persistent_id (the locally minted NOID stored
    # as a plain string instead of an alternate_id Fedora reference).
    #
    # @example
    #   Hyrax.query_service.custom_queries.find_by_emory_persistent_id(
    #     emory_persistent_id: '508hdr7srt-cor'
    #   )
    class FindByEmoryPersistentId < SolrDocumentQuery
      self.queries = [:find_by_emory_persistent_id]

      # @param emory_persistent_id [String] the NOID string to look up
      # @return [Valkyrie::Resource] when a record was found
      # @raise [Valkyrie::Persistence::ObjectNotFoundError] when no record was found
      def find_by_emory_persistent_id(emory_persistent_id:)
        @emory_persistent_id = emory_persistent_id
        raise Valkyrie::Persistence::ObjectNotFoundError unless resource
        @query_service.find_by(id: resource['id'])
      end

      def query
        "emory_persistent_id_ssi:#{@emory_persistent_id}"
      end
    end
  end
end
