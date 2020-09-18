# frozen_string_literal: true

module Hyrax
  module CollectionsOverrideHelper
    include Hyrax::CollectionsHelper

    # rubocop:disable Rails/ContentTag
    def render_collection_links(solr_doc)
      collection_list = Hyrax::CollectionMemberService.run(solr_doc, controller.current_ability)
      return if collection_list.empty?
      source_collection = collection_list.first['source_collection_id_tesim'].present? ? [::SolrDocument.find(collection_list.first['source_collection_id_tesim'])] : []
      collection_list |= source_collection
      links = collection_list.map { |collection| link_to collection.title_or_label, hyrax.collection_path(collection.id) }
      collection_links = []
      links.each_with_index do |link, n|
        collection_links << link
        collection_links << ', ' unless links[n + 1].nil?
      end
      content_tag :span, safe_join([t('hyrax.collection.is_part_of'), ': '] + collection_links)
    end
    # rubocop:enable Rails/ContentTag
  end
end
