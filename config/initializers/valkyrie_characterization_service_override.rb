# frozen_string_literal: true
# [Hyrax-override-v5.2.0] Overrides ValkyrieCharacterizationService to add:
#   - Custom checksum handling (MD5 + SHA1 + SHA256)
#   - Alpha channel detection for IIIF
#   - Preservation events for Characterization and Message Digest Calculation

Rails.application.config.to_prepare do
  Hyrax::Characterization::ValkyrieCharacterizationService.class_eval do
    include PreservationEvents

    def self.run(metadata:, file:, user: ::User.system_user, **options)
      event_start = DateTime.current
      characterizer_obj = new(metadata:, file:, **options)
      characterizer_obj.characterize
      characterizer_obj.detect_alpha_channels
      saved = Hyrax.persister.save(resource: metadata)
      file_set = Hyrax.query_service.find_by(id: saved.file_set_id)

      characterizer_obj.process_characterization_event(saved, user, file_set, event_start)
      characterizer_obj.process_digest_event(saved.file_set_id, user, event_start, saved.original_checksum)
      Hyrax.publisher.publish('file.metadata.updated', metadata: saved, user:)
      Hyrax.publisher.publish('file.characterized',
                              file_set:,
                              file_id:   saved.id.to_s,
                              path_hint: saved.file_identifier.to_s)
    end

    def characterize
      terms = parse_metadata(extract_metadata(content))
      transform_original_checksum(terms)
      apply_metadata(terms)
    end

    def transform_original_checksum(terms)
      value = terms[:original_checksum]
      return if value.blank?

      value.first.prepend("urn:md5:").to_s
      value.push(digest_sha1, digest_sha256)
    end

    def detect_alpha_channels
      return unless image_file?

      channels = MiniMagick::Tool::Identify.new do |cmd|
        cmd.format '%[channels]'
        cmd << source_path
      end
      metadata.alpha_channels = [channels] if metadata.respond_to?(:alpha_channels=)
    rescue StandardError => e
      Rails.logger.warn("ValkyrieCharacterizationService: alpha channel detection failed: #{e.message}")
    end

    def process_characterization_event(saved_metadata, user, file_set, event_start)
      populated = check_populated_metadata(saved_metadata)
      event = {
        'type' => 'Characterization',
        'start' => event_start,
        'outcome' => populated ? 'Success' : 'Failure',
        'details' => characterization_event_details(populated, saved_metadata, file_set),
        'software_version' => fits_version_string,
        'user' => user&.uid&.presence || file_set.depositor
      }
      create_preservation_event(file_set, event)
    end

    def process_digest_event(file_set_id, user, event_start, checksum_values)
      file_set = Hyrax.query_service.find_by(id: file_set_id)
      event = {
        'type' => 'Message Digest Calculation',
        'start' => event_start,
        'details' => checksum_values,
        'software_version' => digest_version_string,
        'user' => user&.uid&.presence || file_set.depositor
      }
      event['outcome'] = Array(checksum_values).size >= 3 ? 'Success' : 'Failure'
      create_preservation_event(file_set, event)
    end

    private

      def digest_sha256
        sha = Digest::SHA256.new
        source.rewind
        sha << source.read(4096) until source.eof?
        "urn:sha256:#{sha.hexdigest}"
      end

      def digest_sha1
        sha = Digest::SHA1.new
        source.rewind
        sha << source.read(4096) until source.eof?
        "urn:sha1:#{sha.hexdigest}"
      end

      def check_populated_metadata(saved_metadata)
        %i[height width checksum recorded_size format_label].any? { |attr| saved_metadata.send(attr).present? }
      end

      def characterization_event_details(populated, saved_metadata, file_set)
        if populated
          "preservation_master_file: #{saved_metadata.original_filename} - " \
            "Technical metadata extracted from file, format identified, and file validated"
        else
          "The Characterization Service failed for FileSet #{file_set.id}."
        end
      end

      def image_file?
        metadata.mime_type.to_s.start_with?('image/') && Hyrax.config.iiif_image_server?
      end

      def source_path
        return metadata.file_identifier.to_s.sub('file://', '') if metadata.file_identifier.to_s.start_with?('file://')

        tmpfile = Tempfile.new(['characterize', File.extname(metadata.original_filename.to_s)])
        source.rewind
        tmpfile.binmode
        tmpfile.write(source.read)
        tmpfile.flush
        tmpfile.path
      end

      def fits_version_string
        ENV.fetch('FITS_VERSION', 'FITS v1.5.0')
      end

      def digest_version_string
        "#{fits_version_string}, #{ENV.fetch('FEDORA_VERSION', 'Fedora v4.7.6')}, Ruby Digest library"
      end
  end
end
