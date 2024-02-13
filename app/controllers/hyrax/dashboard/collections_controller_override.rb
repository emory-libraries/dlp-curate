# frozen_string_literal: true
module Hyrax
  module Dashboard
    module CollectionsControllerOverride
      # [Hyrax-overwrite-v3.4.2] We are overwriting the `add_new_banner` method because
      # we are using the collection_banner (L#13) column in uploaded_files table
      # instead of the default. Our uploaded_files table is different compared
      # to Hyrax.
      def add_new_banner(uploaded_file_ids)
        f = uploaded_files(uploaded_file_ids).first
        banner_info = CollectionBrandingInfo.new(
          collection_id: @collection.id,
          filename:      File.split(f.collection_banner_url).last,
          role:          "banner",
          alt_txt:       "",
          target_url:    ""
        )
        banner_info.save f.collection_banner_url
      end

      # [Hyrax-overwrite-v3.4.2] Restrict deletion to admins only
      def destroy
        if current_user.admin? && @collection.destroy
          after_destroy(params[:id])
        else
          after_destroy_error(params[:id])
        end
      end

      # [Hyrax-overwrite-v3.4.2] Creates instance variable for aspace repositories.
      def new
        # Coming from the UI, a collection type id should always be present.  Coming from the API, if a collection type id is not specified,
        # use the default collection type (provides backward compatibility with versions < Hyrax 2.1.0)
        @aspace_repositories = retrieve_aspace_repositories
        collection_type_id = params[:collection_type_id].presence || default_collection_type.id
        @collection.collection_type_gid = CollectionType.find(collection_type_id).to_global_id
        add_breadcrumb t(:'hyrax.controls.home'), root_path
        add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
        add_breadcrumb t('.header', type_title: collection_type.title), request.path
        @collection.try(:apply_depositor_metadata, current_user.user_key)
        form
      end

      private

        def retrieve_aspace_repositories
          service = Aspace::ApiService.new
          formatter = Aspace::FormattingService.new

          repositories =
            begin
              service.authenticate!

              data = service.fetch_repositories
              data.map { |r| formatter.format_repository(r) } || []
            rescue
              Rails.logger.error "Curate failed to authenticate with ArchivesSpace."
              []
            end
          repositories
        end
    end
  end
end
