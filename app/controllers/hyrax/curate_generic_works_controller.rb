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
      render json: ::ManifestBuilderService.build_manifest(presenter: presenter, curation_concern: _curation_concern_type.find(params[:id]))
    end

    # [Hyrax-overwrite-v3.3.0] Restrict deletion to admins only
    def destroy
      title = curation_concern.to_s
      if current_user.admin?
        env = Actors::Environment.new(curation_concern, current_ability, {})
        return unless actor.destroy(env)
        Hyrax.config.callback.run(:after_destroy, curation_concern.id, current_user, warn: false)
        after_destroy_response(title)
      else
        after_destroy_error(title)
      end
    end

    def after_destroy_error(title)
      respond_to do |wants|
        wants.html do
          build_form
          flash[:notice] = "#{title} could not be deleted"
          render 'edit', status: :unprocessable_entity
        end
        wants.json { render_json_response(response_type: :unprocessable_entity, options: { errors: curation_concern.errors }) }
      end
    end
  end
end
