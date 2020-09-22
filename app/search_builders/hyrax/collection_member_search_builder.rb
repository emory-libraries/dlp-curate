# frozen_string_literal: true

# [Hyrax-overwrite-v3.0.0.pre.rc1] Modify #member_of_collection to also search against a source collection's deposit collections
# Change below was necessary to institute Source/Deposit Collection structure.
# For more information, read the SOURCE_DEPOSIT_CHANGES_README.md in dlp-curate's root folder.
module Hyrax
  # This search builder requires that a accessor named "collection" exists in the scope
  class CollectionMemberSearchBuilder < ::SearchBuilder
    include Hyrax::FilterByType
    attr_reader :collection, :search_includes_models

    class_attribute :collection_membership_field
    self.collection_membership_field = 'member_of_collection_ids_ssim'

    # Defines which search_params_logic should be used when searching for Collection members
    self.default_processor_chain += [:member_of_collection]

    # @param [scope] Typically the controller object
    # @param [Symbol] :works, :collections, (anything else retrieves both)
    def initialize(scope:,
                   collection:,
                   search_includes_models: :works)
      @collection = collection
      @search_includes_models = search_includes_models
      super(scope)
    end

    # include filters into the query to only include the collection memebers
    def member_of_collection(solr_parameters)
      ids = [collection.id]
      ids.push(*collection.deposit_collection_ids) if collection.deposit_collection_ids
      formatted_ids = "(#{ids.join(' OR ')})"
      solr_parameters[:fq] ||= []
      solr_parameters[:fq] << "#{collection_membership_field}:#{formatted_ids}"
    end

    private

      def only_works?
        search_includes_models == :works
      end

      def only_collections?
        search_includes_models == :collections
      end
  end
end
