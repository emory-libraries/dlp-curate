# frozen_string_literal: true

# Valkyrie indexer for CollectionResource.
# Mirrors the custom Solr fields from the AF CurateCollectionIndexer.
class CollectionResourceIndexer < Hyrax::PcdmCollectionIndexer
  include Hyrax::Indexer(:emory_basic_metadata)
  include Hyrax::Indexer(:collection_resource)

  def to_solr
    super.tap do |solr_doc|
      solr_doc['member_works_count_isi'] = member_works_count
      solr_doc['title_ssort'] = sort_title
      solr_doc['creator_ssort'] = resource.creator.first
      solr_doc['generic_type_sim'] = ["Collection"]
      solr_doc['banner_path_ss'] = banner_path
      solr_doc['source_collection_title_for_collections_ssim'] = source_collection_title
      solr_doc['deposit_collection_titles_tesim'] = deposit_collection_titles
      solr_doc['deposit_collection_ids_tesim'] = Array(resource.deposit_collection_ids)
    end
  end

  private

    def sort_title
      return unless resource.title.first
      resource.title.first.gsub(/^(an?|the)\s/i, '')
    end

    def banner_path
      cbi = CollectionBrandingInfo.find_by(collection_id: resource.id.to_s, role: 'banner')
      return if cbi.nil? || cbi.local_path.nil?
      path = cbi.local_path
      path.include?('/branding') ? '/branding' + path.split('/branding').last : path
    end

    def source_collection_title
      return if resource.source_collection_id.blank?
      source = Hyrax.query_service.find_by(id: resource.source_collection_id)
      source&.title
    rescue Valkyrie::Persistence::ObjectNotFoundError
      nil
    end

    def deposit_collection_titles
      return if resource.deposit_collection_ids.blank?
      Array(resource.deposit_collection_ids).filter_map do |id|
        col = Hyrax.query_service.find_by(id:)
        col&.title&.first
      rescue Valkyrie::Persistence::ObjectNotFoundError
        nil
      end
    end

    def member_works_count
      Hyrax::SolrService.query(
        Hyrax::SolrQueryBuilderService.construct_query(
          source_collection_id_tesim: resource.id.to_s,
          has_model_ssim:             "CurateGenericWork"
        ), rows: 0
      ).dig('response', 'numFound') || 0
    rescue StandardError
      0
    end
end
