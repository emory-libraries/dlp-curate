# frozen_string_literal: true

# [BlacklightIiifSearch-overwrite-v1.0.0] sets 'Access-Control-Allow-Origin' before sending response.
BlacklightIiifSearch::Controller.class_eval do
  def iiif_search
    response.headers['Access-Control-Allow-Headers'] = '*'
    response.headers['Access-Control-Allow-Credentials'] = 'true'
    _parent_response, @parent_document = fetch(params[:solr_document_id])
    iiif_search = BlacklightIiifSearch::IiifSearch.new(iiif_search_params, iiif_search_config, @parent_document)
    @response, _document_list = search_results(iiif_search.solr_params)
    iiif_search_response = BlacklightIiifSearch::IiifSearchResponse.new(@response, @parent_document, self)
    render json:         iiif_search_response.annotation_list,
           content_type: 'application/json'
  end
end
