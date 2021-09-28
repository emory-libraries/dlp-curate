# frozen_string_literal: true
# [Hyrax-overwrite-v3.1.0]

module Hyrax
  class FileSetsController < ApplicationController # rubocop:disable Metrics/ClassLength
    rescue_from WorkflowAuthorizationException, with: :render_unavailable

    include Blacklight::Base
    include Blacklight::AccessControls::Catalog
    include Hyrax::Breadcrumbs

    before_action :authenticate_user!, except: [:show, :citation, :stats]
    load_and_authorize_resource class: ::FileSet, except: :show
    before_action :build_breadcrumbs, only: [:show, :edit, :stats]
    before_action :set_file_set, only: [:show]

    # provides the help_text view method
    helper PermissionsHelper

    helper_method :curation_concern
    copy_blacklight_config_from(::CatalogController)
    # Define collection specific filter facets.
    configure_blacklight do |config|
      config.search_builder_class = Hyrax::FileSetSearchBuilder
    end

    class_attribute :show_presenter, :form_class
    self.show_presenter = Curate::FileSetPresenter
    self.form_class = Curate::Forms::FileSetEditForm

    # A little bit of explanation, CanCan(Can) sets the @file_set via the .load_and_authorize_resource
    # method. However the interface for various CurationConcern modules leverages the #curation_concern method
    # Thus we have file_set and curation_concern that are aliases for each other.
    attr_accessor :file_set
    alias curation_concern file_set
    private :file_set=
    alias curation_concern= file_set=
    private :curation_concern=
    helper_method :file_set

    layout :decide_layout

    # GET /concern/file_sets/:id
    def edit
      initialize_edit_form
    end

    # GET /concern/parent/:parent_id/file_sets/:id
    def show
      @parent = main_app.polymorphic_path(presenter.parent)
      @fileset_use = presenter.pcdm_use.first unless presenter.pcdm_use.nil?
      files
      if @sf
        @display_file = @sf
        @display_use = 'service_file'
      elsif @if
        @display_file = @if
        @display_use = 'intermediate_file'
      else
        @display_file = @file_set.preservation_master_file
        @display_use = 'preservation_master_file'
      end
      respond_to do |wants|
        wants.html
        wants.json
        additional_response_formats(wants)
      end
    end

    # DELETE /concern/file_sets/:id
    def destroy
      parent = curation_concern.parent
      delete(file_set: curation_concern)
      redirect_to [main_app, parent],
                  notice: view_context.t('hyrax.file_sets.asset_deleted_flash.message')
    end

    # PATCH /concern/file_sets/:id
    def update
      if attempt_update
        after_update_response
      else
        after_update_failure_response
      end
    rescue RSolr::Error::Http => error
      flash[:error] = error.message
      logger.error "FileSetsController::update rescued #{error.class}\n\t#{error.message}\n #{error.backtrace.join("\n")}\n\n"
      render action: 'edit'
    end

    # GET /files/:id/stats
    def stats
      @stats = FileUsage.new(params[:id])
    end

    # GET /files/:id/citation
    def citation; end

    private

      ##
      # @api public
      def delete(file_set:)
        case file_set
        when Valkyrie::Resource
          transactions['file_set.destroy']
            .with_step_args('file_set.remove_from_work' => { user: current_user },
                            'file_set.delete' => { user: current_user })
            .call(curation_concern)
            .value!
        else
          actor.destroy
        end
      end

      ##
      # @api public
      #
      # @note this is provided so that implementing application can override this
      #   behavior and map params to different attributes
      def update_metadata
        case file_set
        when Hyrax::Resource
          change_set = Hyrax::Forms::ResourceForm.for(file_set)

          change_set.validate(attributes) &&
            transactions['change_set.apply'].call(change_set).value_or { false }
        else
          file_attributes = form_class.model_attributes(attributes)
          actor.update_metadata(file_attributes)
        end
      end

      def parent(file_set: curation_concern)
        @parent ||=
          case file_set
          when Hyrax::Resource
            Hyrax.query_service.find_parents(resource: file_set).first
          else
            file_set.parent
          end
      end

      def attempt_update
        if wants_to_revert?
          actor.revert_content(params[:revision])
        elsif params.key?(:file_set)
          if params[:file_set].key?(:files)
            actor.update_content(params[:file_set][:files].first, @file_set.preferred_file)
          else
            update_metadata
          end
        elsif params.key?(:files_files) # version file already uploaded with ref id in :files_files array
          uploaded_files = Array(Hyrax::UploadedFile.find(params[:files_files]))
          actor.update_content(uploaded_files.first)
          update_metadata
        end
      end

      def after_update_response
        respond_to do |wants|
          wants.html do
            link_to_file = view_context.link_to(curation_concern, [main_app, curation_concern])
            redirect_to [main_app, curation_concern], notice: view_context.t('hyrax.file_sets.asset_updated_flash.message', link_to_file: link_to_file)
          end
          wants.json do
            @presenter = show_presenter.new(curation_concern, current_ability)
            render :show, status: :ok, location: polymorphic_path([main_app, curation_concern])
          end
        end
      end

      def after_update_failure_response
        respond_to do |wants|
          wants.html do
            initialize_edit_form
            flash[:error] = "There was a problem processing your request."
            render 'edit', status: :unprocessable_entity
          end
          wants.json { render_json_response(response_type: :unprocessable_entity, options: { errors: curation_concern.errors }) }
        end
      end

      def add_breadcrumb_for_controller
        add_breadcrumb I18n.t('hyrax.dashboard.my.works'), hyrax.my_works_path
      end

      def add_breadcrumb_for_action
        case action_name
        when 'edit'
          add_breadcrumb I18n.t("hyrax.file_set.browse_view"), main_app.hyrax_file_set_path(params["id"])
        when 'show'
          add_breadcrumb presenter.parent.to_s, main_app.polymorphic_path(presenter.parent) if presenter.parent.present?
          add_breadcrumb presenter.to_s, main_app.polymorphic_path(presenter)
        end
      end

      def initialize_edit_form
        @version_list = Hyrax::VersionListPresenter.for(file_set: @file_set)
        @groups = current_user.groups
      end

      def actor
        @actor ||= Hyrax::Actors::FileSetActor.new(@file_set, current_user)
      end

      def attributes
        params.fetch(:file_set, {}).except(:files).permit!.dup # use a copy of the hash so that original params stays untouched when interpret_visibility modifies things
      end

      def presenter
        @presenter ||= begin
                         presenter = show_presenter.new(curation_concern_document, current_ability, request)
                         presenter
                       end
      end

      def curation_concern_document
        # Query Solr for the collection.
        # run the solr query to find the collection members
        response, _docs = single_item_search_service.search_results
        curation_concern = response.documents.first
        raise CanCan::AccessDenied unless curation_concern
        curation_concern
      end

      def single_item_search_service
        Hyrax::SearchService.new(config: blacklight_config, user_params: params.except(:q, :page), scope: self, search_builder_class: search_builder_class)
      end

      def wants_to_revert?
        params.key?(:revision) && params[:revision] != curation_concern.latest_content_version.label
      end

      # Override this method to add additional response formats to your local app
      def additional_response_formats(_); end

      # This allows us to use the unauthorized and form_permission template in hyrax/base,
      # while prefering our local paths. Thus we are unable to just override `self.local_prefixes`
      def _prefixes
        @_prefixes ||= super + ['hyrax/base']
      end

      def decide_layout
        layout = case action_name
                 when 'show'
                   '1_column'
                 else
                   'dashboard'
                 end
        File.join(theme, layout)
      end

      def set_file_set
        @file_set = ::FileSet.find(params[:id])
      end

      def files
        @pm = @file_set.preservation_master_file unless @file_set.preservation_master_file.nil?
        @sf = @file_set.service_file unless @file_set.service_file.nil?
        @if = @file_set.intermediate_file unless @file_set.intermediate_file.nil?
        @et = @file_set.extracted unless @file_set.extracted.nil?
        @tf = @file_set.transcript_file unless @file_set.transcript_file.nil?
      end
  end
end
