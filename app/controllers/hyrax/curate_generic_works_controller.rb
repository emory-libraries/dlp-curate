# frozen_string_literal: true
module Hyrax
  # Generated controller for CurateGenericWork
  class CurateGenericWorksController < ApplicationController
    # Adds Hyrax behaviors to the controller.
    include Hyrax::WorksControllerBehavior
    include Hyrax::BreadcrumbsForWorks
    self.curation_concern_type = ::CurateGenericWork

    # Use this line if you want to use a custom presenter
    self.show_presenter = Hyrax::CurateGenericWorkPresenter

    def show # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      @user_collections = user_collections
      @parent = main_app.polymorphic_path(parent_presenter) if parent_presenter
      if presenter.preservation_workflow_terms
        @preservation_workflow_display = JSON.parse(presenter.preservation_workflow_terms[0]) if presenter.preservation_workflow_terms
        preservation_workflow_display_copy = @preservation_workflow_display.clone
        @preservation_workflow_display.each_key do |key|
          preservation_workflow_display_copy[key.split('_').map(&:capitalize).join(' ')] = preservation_workflow_display_copy.delete(key)
        end
        @preservation_workflow_display = preservation_workflow_display_copy
      end
      respond_to do |wants|
        wants.html { presenter && parent_presenter }
        wants.json do
          # load and authorize @curation_concern manually because it's skipped for html
          @curation_concern = _curation_concern_type.find(params[:id]) unless curation_concern
          authorize! :show, @curation_concern
          render :show, status: :ok
        end
        additional_response_formats(wants)
        wants.ttl do
          render body: presenter.export_as_ttl, content_type: 'text/turtle'
        end
        wants.jsonld do
          render body: presenter.export_as_jsonld, content_type: 'application/ld+json'
        end
        wants.nt do
          render body: presenter.export_as_nt, content_type: 'application/n-triples'
        end
      end
    end

    def manifest
      headers['Access-Control-Allow-Origin'] = '*'
      manifest_builder
    end

    private

      def manifest_builder
        solr_doc = ::SolrDocument.find(params[:id])
        date_modified = solr_doc[:date_modified_dtsi] || solr_doc[:system_create_dtsi]
        key = date_modified.to_datetime.strftime('%Y-%m-%d_%H-%M-%S') + '_' + solr_doc[:id]

        if File.exist?(Rails.root.join('tmp', key))
          render_manifest_file(key: key)
        else
          manifest_hash = ::IIIFManifest::ManifestFactory.new(presenter).to_h
          persist_manifest(key: key, manifest_hash: manifest_hash)
          render json: manifest_hash.to_json
        end
      end

      def render_manifest_file(key:)
        manifest_file = File.open(Rails.root.join('tmp', key))
        render json: manifest_file.read
        manifest_file.close
      end

      def persist_manifest(key:, manifest_hash:)
        File.open(Rails.root.join('tmp', key), 'w+') do |f|
          f.write(manifest_hash.to_json)
        end
      end
  end
end
