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
        Hyrax.index_adapter.save(resource: file_set)
        preferred_file_metadata = file_set.public_send(file_set.preferred_file)

        return if preferred_file_metadata.blank?

        case file_set
        when ActiveFedora::Base # ActiveFedora
          CreateDerivativesJob
            .perform_later(file_set, preferred_file_metadata.id.to_s, event[:path_hint]) # Emory Alteration
        else
          ValkyrieCreateDerivativesJob
            .perform_later(file_set.id.to_s, preferred_file_metadata.id.to_s) # Emory Alteration
        end
      end

      ##
      # Called when 'file.uploaded' event is published
      # @param [Dry::Events::Event] event
      # @return [void]
      def on_file_uploaded(event)
        # Run characterization for original file only and allow optional skip paramater
        ValkyrieCharacterizationJob.perform_later(event[:metadata].id.to_s)
      end
    end
  end
end
