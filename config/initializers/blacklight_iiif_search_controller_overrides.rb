# frozen_string_literal: true

# [BlacklightIiifSearch-overwrite-v1.0.0] sets 'Access-Control-Allow-Origin' before sending response.
BlacklightIiifSearch::Controller.class_eval do
  # allow apps to load JSON received from a remote server
  def set_access_headers
    response.headers['Access-Control-Allow-Origin'] = 'https://digital-test.library.emory.edu'
  end
end
