# frozen_string_literal: true

class CurateCollectionIndexer < Hyrax::CollectionIndexer
  def rdf_service
    CurateIndexer
  end

  # Change below was necessary to institute Source/Deposit Collection structure.
  # For more information, read the SOURCE_DEPOSIT_CHANGES_README.md in dlp-curate's root folder.
  def generate_solr_document
    super.tap do |solr_doc|
      solr_doc['member_works_count_isi'] = member_works_count
      solr_doc['title_ssort'] = sort_title
      solr_doc['creator_ssort'] = object.creator.first
      solr_doc['generic_type_sim'] = ["Collection"]
      solr_doc['banner_path_ss'] = banner_path
      solr_doc['source_collection_title_for_collections_ssim'] = source_collection
      solr_doc['deposit_collection_titles_tesim'] = deposit_collection
      solr_doc['deposit_collection_ids_tesim'] = object.deposit_collection_ids
    end
  end

  def sort_title
    return unless object.title.first
    object.title.first.gsub(/^(an?|the)\s/i, '')
  end

  def banner_path
    cbi = branding_details
    path_sanitized(cbi.local_path) unless cbi.nil? || cbi&.local_path&.nil?
  end

  def branding_details
    CollectionBrandingInfo.find_by_collection_id_and_role object.id, 'banner'
  end

  def path_sanitized(path)
    return '/branding' + path.split('/branding').last if path&.include? '/branding'
    path
  end

  # Change below was necessary to institute Source/Deposit Collection structure.
  # For more information, read the SOURCE_DEPOSIT_CHANGES_README.md in dlp-curate's root folder.
  def source_collection
    collection = Collection.find(object.source_collection_id) if object.source_collection_id
    return collection.title unless collection.nil?
  end

  def deposit_collection
    object.deposit_collection_ids.map { |id| Collection.find(id).title.first } if object.deposit_collection_ids.present?
  end

  def member_works_count
    Collection.related_works_solrized(object.id).count
  end
end
