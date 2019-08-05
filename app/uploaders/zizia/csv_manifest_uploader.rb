# frozen_string_literal: true

require 'carrierwave'

module Zizia
  class CsvManifestUploader < CarrierWave::Uploader::Base
    # Choose what kind of storage to use for this uploader:
    storage :file

    # Process calls that method whenever a file is uploaded.
    process :validate_csv

    # The directory where the csv manifest will be stored.
    def store_dir
      configured_upload_path + "#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
    end

    def cache_dir
      configured_cache_path + "#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
    end

    # Add a white list of extensions which are allowed to be uploaded.
    # For images you might use something like this:
    #   %w(jpg jpeg gif png)
    def extension_whitelist
      %w[csv]
    end

    # These are stored in memory only, not persisted
    def errors
      @validator ? @validator.errors : []
    end

    # These are stored in memory only, not persisted
    def warnings
      @validator ? @validator.warnings : []
    end

    def records
      @validator ? @validator.record_count : 0
    end

    private

      def validate_csv
        @validator = CsvManifestValidator.new(self)
        @validator.validate
      end

      def configured_upload_path
        ENV['CSV_MANIFESTS_PATH'] || base_path_uploads + 'csv_uploads'
      end

      def configured_cache_path
        ENV['CSV_MANIFESTS_CACHE_PATH'] || base_path_cache + 'csv_uploads/cache'
      end

      def base_path_uploads
        ENV['CI'] ? Rails.root : Hyrax.config.upload_path.call
      end

      def base_path_cache
        ENV['CI'] ? Rails.root : Hyrax.config.cache_path.call
      end
  end
end
