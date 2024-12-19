# frozen_string_literal: true

# [BlacklightIiifSearch-overwrite-v1.0.0] sets 'Access-Control-Allow-Origin' before sending response.
BlacklightIiifSearch::Controller.class_eval do
   skip_before_action :authenticate_user!
end
