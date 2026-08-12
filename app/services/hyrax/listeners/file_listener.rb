# frozen_string_literal: true
# [Hyrax-override-v5.2.0] L#34 Since we sometimes user `intermediate_file` for derivatives
#   and characterization, we remove the not `original_file` examption.

module Hyrax
  module Listeners
    ##
    # Listens for events related to Files ({Valkyrie::StorageAdapter::File})
    class FileListener
      ##
      # Called when 'file.characterized' event is published;
      # allows post-characterization handling, like derivatives generation.
      #
      # @param [Dry::Events::Event] event
      # @return [void]
      def on_file_characterized(event)
        file_set = event[:file_set]

        case file_set
        when ActiveFedora::Base # ActiveFedora
          CreateDerivativesJob
            .perform_later(file_set, event[:file_id], event[:path_hint])
        else
          ValkyrieCreateDerivativesJob
            .perform_later(file_set.id.to_s, event[:file_id])
        end
      end

      ##
      # Called when 'file.uploaded' event is published
      # @param [Dry::Events::Event] event
      # @return [void]
      def on_file_uploaded(event)
        if event[:metadata]&.original_file?
          # Run characterization for original file only and allow optional skip paramater
          ValkyrieCharacterizationJob.perform_later(event[:metadata].id.to_s)
        elsif curate_preferred_derivative_files.include?(event[:metadata].pcdm_use.first) # Emory Addition
          file_set = Hyrax.query_service.find_by(id: event[:metadata].file_set_id)

          case file_set
          when ActiveFedora::Base # ActiveFedora
            CreateDerivativesJob
              .perform_later(file_set, event[:metadata].id.to_s, event[:metadata].file_identifier.to_s)
          else
            ValkyrieCreateDerivativesJob
              .perform_later(file_set.id.to_s, event[:metadata].id.to_s)
          end
        end
      end

      private

        def curate_preferred_derivative_files
          [Hyrax::FileMetadata::Use::INTERMEDIATE_FILE, Hyrax::FileMetadata::Use::SERVICE_FILE]
        end
    end
  end
end
