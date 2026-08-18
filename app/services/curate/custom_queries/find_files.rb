# frozen_string_literal: true
module Curate
  module CustomQueries
    ##
    # @example
    #   Hyrax.custom_queries.find_intermediate_file(file_set: file_set_resource)
    #   Hyrax.custom_queries.find_service_file(file_set: file_set_resource)
    #
    # @see https://github.com/samvera/valkyrie/wiki/Queries#custom-queries
    # @since 3.0.0
    class FindFiles
      def self.queries
        [:find_intermediate_file,
         :find_service_file]
      end

      def initialize(query_service:)
        @query_service = query_service
      end

      attr_reader :query_service
      delegate :resource_factory, to: :query_service

      # Find intermediate file id of a given file set resource, and map to file metadata resource
      # @param file_set [Hyrax::FileSet]
      # @return [Hyrax::FileMetadata]
      def find_intermediate_file(file_set:)
        find_exactly_one_file_by_use(
          file_set:,
          use:      Hyrax::FileMetadata::Use::INTERMEDIATE_FILE
        )
      end

      # Find service file id of a given file set resource, and map to file metadata resource
      # @param file_set [Hyrax::FileSet]
      # @return [Hyrax::FileMetadata]
      def find_service_file(file_set:)
        find_exactly_one_file_by_use(
          file_set:,
          use:      Hyrax::FileMetadata::Use::SERVICE_FILE
        )
      end

      # Find transcript file id of a given file set resource, and map to file metadata resource
      # @param file_set [Hyrax::FileSet]
      # @return [Hyrax::FileMetadata]
      def find_transcript_file(file_set:)
        find_exactly_one_file_by_use(
          file_set:,
          use:      Valkyrie::Vocab::PCDMUse.Transcript
        )
      end

      private

        ##
        # @api private
        #
        # @return [Hyrax::FileMetadata]
        # @raise [Valkyrie::Persistence::ObjectNotFoundError]
        def find_exactly_one_file_by_use(file_set:, use:)
          files =
            query_service.custom_queries.find_many_file_metadata_by_use(resource: file_set, use:)

          files.first || raise(Valkyrie::Persistence::ObjectNotFoundError, "FileSet #{file_set.id}'s #{use.fragment} is missing.")
        end
    end
  end
end
