# frozen_string_literal: true
module Hyrax
  module Dashboard
    module CollectionsControllerOverride
      # [Hyrax-overwrite-v3.2.0] We are overwriting the `add_new_banner` method because
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

      # [Hyrax-overwrite-v3.2.0] Restrict deletion to admins only
      def destroy
        return admin_destroy_processing if current_user.admin?
        after_destroy_error(params[:id])
      rescue StandardError => err
        destroy_error_processing(err)
      end

      private

        def admin_valkyrie_processing
          Hyrax.persister.delete(resource: @collection)
          after_destroy(params[:id])
        end

        def destroy_error_processing(err)
          Rails.logger.error(err)
          after_destroy_error(params[:id])
        end

        def admin_destroy_processing
          return admin_valkyrie_processing if @collection == Valkyrie::Resource
          return after_destroy(params[:id]) if @collection.destroy
          after_destroy_error(params[:id])
        end
    end
  end
end
