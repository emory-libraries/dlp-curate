# frozen_string_literal: true

# [Hyrax-overwrite-v3.1.0] Modify #member_of_collection to also search against a source collection's deposit collections
# Change below was necessary to institute Source/Deposit Collection structure.
# For more information, read the SOURCE_DEPOSIT_CHANGES_README.md in dlp-curate's root folder.
module Hyrax
  # This search builder requires that a accessor named "collection" exists in the scope
  class MultiLevelCollectionMemberSearchBuilder < ::Hyrax::CollectionMemberSearchBuilder
    # include filters into the query to only include the collection memebers
    def member_of_collection(solr_parameters)
      ids = [collection.id]
      ids.push(*collection.deposit_collection_ids) if collection.deposit_collection_ids
      formatted_ids = "(#{ids.join(' OR ')})"
      solr_parameters[:fq] ||= []
      solr_parameters[:fq] << "#{collection_membership_field}:#{formatted_ids}"
    end
  end
end
