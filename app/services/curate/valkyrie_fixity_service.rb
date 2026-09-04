# frozen_string_literal: true

module Curate
  # Valkyrie-compatible fixity service that verifies file integrity by comparing
  # stored checksums against freshly computed checksums from the storage adapter.
  # Replaces Fedora's fixity endpoint for files managed by Valkyrie.
  class ValkyrieFixityService
    attr_reader :file_set, :file_metadata

    # @param file_set [Hyrax::FileSet, FileSetResource] the file set to check
    def initialize(file_set)
      raise ArgumentError, 'You must provide a FileSet object' unless file_set
      @file_set = file_set
      @file_metadata = Hyrax.custom_queries
                            .find_many_file_metadata_by_use(resource: file_set, use: Hyrax::FileMetadata::Use::ORIGINAL_FILE)
                            .first
    end

    # @return [String] the checked URI (file identifier)
    def target
      @file_metadata&.file_identifier.to_s
    end

    # @return [String] expected digest in "urn:sha1:..." format
    def expected_message_digest
      checksum = Array(@file_metadata&.original_checksum).find { |c| c.to_s.start_with?('urn:sha1:') }
      checksum&.to_s || compute_sha1_urn
    end

    # Performs the fixity check by recomputing the checksum and comparing to stored value.
    # @return [Boolean] true if fixity is intact
    def check
      return false unless @file_metadata&.file_identifier

      stored_checksum = normalized_stored_sha1
      return false if stored_checksum.blank?

      computed_checksum = compute_file_sha1
      return false if computed_checksum.blank?

      stored_checksum == computed_checksum
    rescue Valkyrie::StorageAdapter::FileNotFound
      false
    end

    private

      def normalized_stored_sha1
        raw = Array(@file_metadata.original_checksum).find { |c| c.to_s.include?('sha1') }
        return raw.to_s.sub('urn:sha1:', '') if raw.to_s.start_with?('urn:sha1:')
        raw.to_s.presence
      end

      def compute_file_sha1
        file = Hyrax.storage_adapter.find_by(id: @file_metadata.file_identifier)
        Digest::SHA1.hexdigest(file.read)
      end

      def compute_sha1_urn
        sha1 = compute_file_sha1
        sha1 ? "urn:sha1:#{sha1}" : ''
      rescue Valkyrie::StorageAdapter::FileNotFound
        ''
      end
  end
end
