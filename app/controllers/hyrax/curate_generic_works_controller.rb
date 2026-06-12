# frozen_string_literal: true
# [Hyrax-override-hyrax-v5.2.0]

module Hyrax
  # Generated controller for CurateGenericWork
  class CurateGenericWorksController < ApplicationController
    # Adds Hyrax behaviors to the controller.
    include Hyrax::WorksControllerBehavior
    include Hyrax::BreadcrumbsForWorks

    if Hyrax.config.valkyrie_transition?
      self.curation_concern_type = ::CurateGenericWorkResource
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
          @curation_concern = load_curation_concern
          curation_concern # This is here for authorization checks (we could add authorize! but let's use the same method for CanCanCan)
          render :show, status: :ok
        end
        additional_response_formats(wants)
      end
    end

    def manifest
      headers['Access-Control-Allow-Origin'] = '*'
      render json: ::ManifestBuilderService.build_manifest(presenter:, curation_concern: load_curation_concern_for_manifest)
    end

    # Restrict deletion to admins only.
    # Supports both AF and Valkyrie works during lazy migration.
    def destroy
      return after_destroy_error(curation_concern.to_s) unless current_user.admin?

      title = curation_concern.is_a?(ActiveFedora::Base) ? destroy_af_work : destroy_valkyrie_work
      return unless title

      after_destroy_response(title)
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

    private

      # @return [String, nil] the title to display in the flash, or nil if destroy
      #   failed (in which case `actor.destroy` has already rendered a response).
      def destroy_af_work
        title = curation_concern.to_s
        env = Actors::Environment.new(curation_concern, current_ability, {})
        return nil unless actor.destroy(env)
        Hyrax.config.callback.run(:after_destroy, curation_concern.id, current_user, warn: false)
        title
      end

      # @return [String] the title to display in the flash after Valkyrie destroy.
      def destroy_valkyrie_work
        transactions['work_resource.destroy']
          .with_step_args('work_resource.delete' => { user: current_user },
                          'work_resource.delete_all_file_sets' => { user: current_user })
          .call(curation_concern).value!
        Array(curation_concern.title).first
      end

      # Loads the curation concern for IIIF manifest rendering, supporting both
      # AF and Valkyrie resources during lazy migration.
      def load_curation_concern_for_manifest
        if Hyrax.config.valkyrie_transition?
          Hyrax.query_service.find_by(id: params[:id])
        else
          _curation_concern_type.find(params[:id])
        end
      end
  end
end
