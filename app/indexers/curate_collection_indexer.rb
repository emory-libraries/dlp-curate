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
    path_sanitized(cbi.local_path) unless cbi.nil? || cbi&.local_path&.nil?
  end

  def branding_details
    CollectionBrandingInfo.find_by_collection_id_and_role object.id, 'banner'
  end

  def path_sanitized(path)
    if ENV['BRANDING_PATH'].present? && path.include?(ENV['BRANDING_PATH'].to_s)
      path.gsub ENV['BRANDING_PATH'], '/branding'
    elsif path.include? Rails.root.join('public', 'branding').to_s
      path.gsub Rails.root.join('public').to_s, ''
    else
      path
    end
  end
end
