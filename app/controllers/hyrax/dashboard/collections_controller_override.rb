# frozen_string_literal: true
module Hyrax
  module Dashboard
    module CollectionsControllerOverride
      # [Hyrax-overwrite] We are overwriting the `add_new_banner` method because
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
    end
  end
end
