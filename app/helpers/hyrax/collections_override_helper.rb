# frozen_string_literal: true

module Hyrax
  module CollectionsOverrideHelper
    include Hyrax::CollectionsHelper

    def pull_collection_list(solr_doc)
      Hyrax::CollectionMemberService.run(solr_doc, controller.current_ability)
    end

    def source_collection(id)
      id.present? ? [::SolrDocument.find(id)] : []
    end

    # [Hyrax-overwrite-hyrax-v5.2.0] We change the pulling of the collection list to our preferred methods above.
    # rubocop:disable Rails/ContentTag
    def render_collection_links(solr_doc)
      return if pull_collection_list(solr_doc).empty?
      collection_list = pull_collection_list(solr_doc) | source_collection(pull_collection_list(solr_doc).first['source_collection_id_tesim'])
      links = collection_list.map { |collection| link_to collection.title_or_label, hyrax.collection_path(collection.id) }
      collection_links = []
      links.each_with_index do |link, n|
        collection_links << link
        collection_links << ', ' unless links[n + 1].nil?
      end
      tag.span safe_join([t('hyrax.collection.is_part_of'), ': '] + collection_links)
    end
    # rubocop:enable Rails/ContentTag
  end
end
