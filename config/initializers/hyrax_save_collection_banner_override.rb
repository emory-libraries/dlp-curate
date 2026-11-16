# frozen_string_literal: true
# [Hyrax-override-v5.2.0] Overrides SaveCollectionBanner to use `collection_banner_url`
# instead of `file_url`. dlp-curate's UploadedFile uses the `collection_banner` column
# (not the stock `file` column) for banner uploads.

if Hyrax.config.valkyrie_transition?
  Rails.application.config.to_prepare do
    Hyrax::Transactions::Steps::SaveCollectionBanner.class_eval do
      private

        def add_new_banner(collection_id:, uploaded_file_ids:)
          f = uploaded_files(uploaded_file_ids).first
          banner_info = CollectionBrandingInfo.new(
            collection_id:,
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
