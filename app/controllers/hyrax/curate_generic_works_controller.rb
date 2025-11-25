# frozen_string_literal: true
# [Hyrax-overwrite-hyrax-v5.2.0]

module Hyrax
  # Generated controller for CurateGenericWork
  class CurateGenericWorksController < ApplicationController
    # Adds Hyrax behaviors to the controller.
    include Hyrax::WorksControllerBehavior
    include Hyrax::BreadcrumbsForWorks

    if Hyrax.config.valkyrie_transition?
      self.curation_concern_type = ::GenericWorkResource
      self.work_form_service = Hyrax::FormFactory.new
    else
      self.curation_concern_type = ::CurateGenericWork
    end

    # Use this line if you want to use a custom presenter
    self.show_presenter = Hyrax::CurateGenericWorkPresenter

    def show # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      @user_collections = user_collections
      @parent = main_app.polymorphic_path(parent_presenter) if parent_presenter
      respond_to do |wants|
        wants.html { presenter && parent_presenter }
        wants.json do
          # load @curation_concern manually because it's skipped for html
          @curation_concern = Hyrax.query_service.find_by_alternate_identifier(alternate_identifier: params[:id])
          curation_concern # This is here for authorization checks (we could add authorize! but let's use the same method for CanCanCan)
          render :show, status: :ok
        end
        additional_response_formats(wants)
      end
    end

    def manifest
      headers['Access-Control-Allow-Origin'] = '*'
      render json: ::ManifestBuilderService.build_manifest(presenter: presenter, curation_concern: _curation_concern_type.find(params[:id]))
    end

    # Restrict deletion to admins only
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
