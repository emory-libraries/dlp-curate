# frozen_string_literal: true

class CurateCollectionIndexer < Hyrax::CollectionIndexer
  def rdf_service
    CurateIndexer
  end

  def generate_solr_document
    super.tap do |solr_doc|
      solr_doc['member_works_count_isi'] = object.child_works.count
      solr_doc['title_ssort'] = sort_title
      solr_doc['creator_ssort'] = object.creator.first
      solr_doc['generic_type_sim'] = ["Collection"]
      solr_doc['banner_path_ss'] = banner_path
    end
  end

  def sort_title
    return unless object.title.first
    object.title.first.gsub(/^(an?|the)\s/i, '')
  end

  def banner_path
    cbi = branding_details
    cbi.nil? || cbi&.local_path&.nil? ? '' : cbi.local_path
  end

  def branding_details
    CollectionBrandingInfo.find_by_collection_id_and_role object.id, 'banner'
  end
end
