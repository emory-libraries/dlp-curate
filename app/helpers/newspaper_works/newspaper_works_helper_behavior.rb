# frozen_string_literal: true
# gem 'newspaper_works', v1.0.2
# Refer to the gem repository for more details: https://github.com/samvera-labs/newspaper_works
# Released under license Apache License 2.0: https://github.com/samvera-labs/newspaper_works/blob/main/LICENSE
# This gem is not yet compatible with Hyrax v3, hence why I am only using the portions relevant to our use case
# This gem is used for keyword highlighting in search results

module NewspaperWorks
  module NewspaperWorksHelperBehavior
    ##
    # create link anchor to be read by UniversalViewer
    # in order to show keyword search
    # @param query_params_hash [Hash] current_search_session.query_params
    # @return [String] or [nil] anchor
    def iiif_search_anchor(query_params_hash)
      query = search_query(query_params_hash)
      return nil if query.blank?
      "?h=#{query}"
    end

    ##
    # get the query, which may be in a different object,
    #   depending if regular search or newspapers_search was run
    # @param query_params_hash [Hash] current_search_session.query_params
    # @return [String] or [nil] query
    def search_query(query_params_hash)
      query_params_hash[:q] || query_params_hash[:all_fields]
    end

    ##
    # based on Blacklight::CatalogHelperBehavior#render_thumbnail_tag
    # setup the thumbnail link for a NewspaperPage or Article
    #
    # @param document [SolrDocument]
    # @param query_params_hash [Hash] current_search_session.query_params
    # @return [String]
    def render_newspaper_thumbnail_tag(document, query_params_hash)
      thumbnail = newspaper_thumbnail_tag(document)
      return unless thumbnail
      anchor = iiif_search_anchor(query_params_hash)
      case document[blacklight_config.view_config(document_index_view_type).display_type_field].first
      when 'NewspaperPage'
        link_to(thumbnail, hyrax_newspaper_page_path(document.id, anchor: anchor))
      when 'NewspaperArticle'
        link_to(thumbnail, hyrax_newspaper_article_path(document.id, anchor: anchor))
      else
        link_to_document document, thumbnail
      end
    end

    ##
    # based on Blacklight::CatalogHelperBehavior#render_thumbnail_tag
    # return the thumbnail image_tag
    #
    # @param document [SolrDocument]
    # @return [String]
    def newspaper_thumbnail_tag(document)
      if blacklight_config.view_config(document_index_view_type).thumbnail_method
        send(blacklight_config.view_config(document_index_view_type).thumbnail_method,
             document)
      elsif blacklight_config.view_config(document_index_view_type).thumbnail_field
        url = thumbnail_url(document)
        image_tag url if url.present?
      end
    end

    ##
    # return the matching highlighted terms from Solr highlight field
    #
    # @param document [SolrDocument]
    # @param hl_fl [String] the name of the Solr field with highlights
    # @param hl_tag [String] the HTML element name used for marking highlights
    #   configured in Solr as hl.tag.pre value
    # @return [String]
    def highlight_matches(document, hl_fl, hl_tag)
      hl_matches = []
      # regex: find all chars between hl_tag, but NOT other <element>
      regex = /<#{hl_tag}>[^<>]+<\/#{hl_tag}>/
      hls = document.highlight_field(hl_fl)
      return nil if hls.blank?
      hls.each do |hl|
        matches = hl.scan(regex)
        matches.each do |match|
          hl_matches << match.gsub(/<[\/]*#{hl_tag}>/, '').downcase
        end
      end
      hl_matches.uniq.sort.join(' ')
    end

    ##
    # print the ocr snippets. if more than one, separate with <br/>
    #
    # @param options [Hash] options hash provided by Blacklight
    # @return [String] snippets HTML to be rendered
    # rubocop:disable Rails/OutputSafety
    def render_ocr_snippets(options = {})
      snippets = options[:value]
      snippets_content = [tag.div("... #{snippets.first} ...".html_safe,
                                      class: 'ocr_snippet first_snippet')]
      if snippets.length > 1
        snippets_content << render(partial: 'catalog/snippets_more',
                                   locals:  { snippets: snippets.drop(1),
                                              options:  options })
      end
      snippets_content.join("\n").html_safe
    end
    # rubocop:enable Rails/OutputSafety
  end
end
