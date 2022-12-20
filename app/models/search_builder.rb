# frozen_string_literal: true

require './app/lib/newspaper_works/highlight_search_params.rb'

class SearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  # Add a filter query to restrict the search to documents the current user has access to
  include Hydra::AccessControlsEnforcement
  include Hyrax::SearchFilters
  include NewspaperWorks::HighlightSearchParams

  self.default_processor_chain += [:highlight_search_params]

  ##
  # @example Adding a new step to the processor chain
  #   self.default_processor_chain += [:add_custom_data_to_query]
  #
  #   def add_custom_data_to_query(solr_parameters)
  #     solr_parameters[:custom] = blacklight_params[:user_value]
  #   end
end
