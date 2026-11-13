# frozen_string_literal: true
# [Hyrax-override-hyrax-v5.2.0]
# Default Admin Set show 404s during Valkyrie transition because:
#   1. load_and_authorize_resource looks the object up in Fedora 6 first; legacy
#      AF objects (especially id "admin_set/default") can miss that lookup.
#   2. The show page itself is Solr-backed, same as work show pages.
# Skip the persistence load for show and fall back to Solr so the collection
# view still renders when the object is indexed but not yet migrated.
module Hyrax
  module Admin
    module AdminSetsControllerOverride
      def self.prepended(base)
        base.skip_load_and_authorize_resource only: :show
        already_set = base._process_action_callbacks.any? { |callback| callback.filter == :unescape_admin_set_id }
        base.prepend_before_action :unescape_admin_set_id unless already_set
      end

      def show
        @admin_set = find_admin_set_for_show
        authorize! :read, @admin_set
        super
      end

      private

        def unescape_admin_set_id
          params[:id] = CGI.unescape(params[:id].to_s) if params[:id].present?
        end

        def find_admin_set_for_show
          Hyrax.query_service.find_by(id: params[:id])
        rescue Valkyrie::Persistence::ObjectNotFoundError, Hyrax::ObjectNotFoundError, Ldp::BadRequest, Ldp::HttpError, Faraday::Error
          solr_document_for_admin_set
        end

        # SolrDocument.find uses Blacklight's /get document handler, which this
        # app's Solr config does not define. The show presenter already loads
        # via SearchService (select + {!raw f=id}), so reuse that.
        def solr_document_for_admin_set
          response, = search_service.search_results
          response.documents.first || raise(Hyrax::ObjectNotFoundError)
        end
    end
  end
end
