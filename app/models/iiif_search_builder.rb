# frozen_string_literal: true

# SearchBuilder for full-text searches with highlighting and snippets
class IiifSearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior

  self.default_processor_chain += [:ocr_search_params]

  # set params for ocr field searching
  def ocr_search_params(solr_parameters = {})
    # 1. Manually check for both symbol and string keys to bypass the BL7 parsing bug
    f_params = search_state.params['f']

    if f_params
      parent_id = f_params['is_page_of_ssi']
      if parent_id.present?
        solr_parameters[:fq] ||= []
        solr_parameters[:fq] << "is_page_of_ssi:#{parent_id}"
      end
    end

    solr_parameters[:facet] = false
    solr_parameters[:hl] = true
    solr_parameters[:'hl.fl'] = blacklight_config.iiif_search[:full_text_field]
    solr_parameters[:'hl.fragsize'] = 100
    solr_parameters[:'hl.snippets'] = 10
  end
end
