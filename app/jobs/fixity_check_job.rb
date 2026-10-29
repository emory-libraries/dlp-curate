# frozen_string_literal: true
# [Hyrax-override-hyrax-v5.2.0] Adds fixity_check preservation_event
# and dual-path support for ActiveFedora and Valkyrie file sets.

require 'sidekiq-limit_fetch'

# rubocop:disable Metrics/ClassLength
class FixityCheckJob < Hyrax::ApplicationJob
  queue_as :fixity_check_job
  include PreservationEvents
  # A Job class that runs a fixity check (using Hyrax.config.fixity_service for AF,
  # or Curate::ValkyrieFixityService for Valkyrie) and stores the results
  # in an ActiveRecord ChecksumAuditLog row. It also prunes old ChecksumAuditLog
  # rows after creating a new one, to keep old ones you don't care about from
  # filling up your db.
  #
  # For AF, the uri passed in is a fedora URI that fedora can run fixity check on.
  # It's normally a version URI like:
  #     http://localhost:8983/fedora/rest/test/a/b/c/abcxyz/content/fcr:versions/version1
  #
  # For Valkyrie, the fixity check recomputes the SHA1 checksum of the stored file
  # and compares it against the recorded original_checksum in FileMetadata.
  #
  # Supports two calling conventions:
  #   AF:       perform(uri, file_set_id:, file_id:, initiating_user:)
  #   Valkyrie: perform(file_set_id:, initiating_user:)
  #
  # @param uri [String] (AF only) uri of the specific file/version to fixity check
  # @param file_set_id [String] the id for FileSet parent object of URI being checked
  # @param file_id [String] (AF only) File#id, used for logging/reporting
  # @param initiating_user [String] the user that kicked off the job
  def perform(*args, file_set_id:, file_id: nil, initiating_user:)
    uri = args.first
    @initiating_user = initiating_user

    if uri.present?
      perform_af(uri, file_set_id, file_id)
    else
      perform_valkyrie(file_set_id)
    end
  end

  private

    # --- Valkyrie path ---

    # rubocop:disable Metrics/MethodLength
    def perform_valkyrie(file_set_id)
      event_start = DateTime.current
      @file_set = Hyrax.query_service.find_by(id: file_set_id)
      @file_metadata = Hyrax.custom_queries
                            .find_many_file_metadata_by_use(resource: @file_set, use: Hyrax::FileMetadata::Use::ORIGINAL_FILE)
                            .first

      service = Curate::ValkyrieFixityService.new(@file_set)
      passed = service.check
      expected_result = service.expected_message_digest

      audit = ChecksumAuditLog.create_and_prune!(passed:,
                                                 file_set_id:     @file_set.id.to_s,
                                                 checked_uri:     service.target,
                                                 file_id:         @file_metadata&.id.to_s,
                                                 expected_result:)

      result = audit.failed? ? :failure : :success
      announce_fixity_check_results(@file_set, audit, result)
      valkyrie_preservation_event(audit.passed, event_start)
      audit
    end
    # rubocop:enable Metrics/MethodLength

    def valkyrie_preservation_event(log, event_start)
      file_name = valkyrie_original_file_name
      checksum = valkyrie_original_checksum
      event = { 'type' => 'Fixity Check', 'start' => event_start,
                'software_version' => 'Hyrax valkyrie_fixity_service', 'user' => @initiating_user }

      if log == true
        event['outcome'] = 'Success'
        event['details'] = "Fixity intact for file: #{file_name}: sha1: #{checksum}"
      else
        event['outcome'] = 'Failure'
        event['details'] = "Fixity check failed for: #{file_name}: sha1: #{checksum}"
      end
      create_preservation_event(@file_set, event)
    end

    def valkyrie_original_file_name
      Array(@file_metadata&.original_filename).first ||
        @file_metadata&.label.to_s ||
        @file_set&.label.to_s
    end

    def valkyrie_original_checksum
      Array(@file_metadata&.original_checksum).find { |c| c.to_s.include?('sha1') }.to_s
    end

    # --- ActiveFedora path ---

    def perform_af(uri, file_set_id, file_id)
      event_start = DateTime.current
      run_check_af(file_set_id, file_id, uri).tap do |audit|
        result = audit.failed? ? :failure : :success
        file_set = ::FileSet.find(file_set_id)

        announce_fixity_check_results(file_set, audit, result)
        af_preservation_event(audit.passed, file_set_id, file_id, event_start)
      end
    end

    def run_check_af(file_set_id, file_id, uri)
      service = fixity_service_for(id: uri)
      expected_result = service.expected_message_digest

      ChecksumAuditLog.create_and_prune!(passed: service.check, file_set_id:, checked_uri: uri.to_s, file_id:, expected_result:)
    rescue Hyrax::Fixity::MissingContentError
      ChecksumAuditLog.create_and_prune!(passed: false, file_set_id:, checked_uri: uri.to_s, file_id:, expected_result:)
    end

    def fixity_service_for(id:)
      Hyrax::Fixity::ActiveFedoraFixityService.new(id)
    end

    def af_preservation_event(log, file_set_id, file_id, event_start)
      fixity_file_set = ::FileSet.find(file_set_id)
      fixity_file = Hydra::PCDM::File.find(file_id)
      event = { 'type' => 'Fixity Check', 'start' => event_start,
                'software_version' => 'Fedora v4.7.6', 'user' => @initiating_user }

      if log == true
        event['outcome'] = 'Success'
        event['details'] = "Fixity intact for file: #{fixity_file&.original_name}: sha1:#{fixity_file&.checksum&.value}"
      else
        event['outcome'] = 'Failure'
        event['details'] = "Fixity check failed for: #{fixity_file&.original_name}: sha1:#{fixity_file&.checksum&.value}"
      end
      CreatePreservationEventJob.perform_later(object: fixity_file_set, event:)
    end

    # --- Shared ---

    def announce_fixity_check_results(file_set, audit, result)
      Hyrax.publisher.publish('file.set.audited', file_set:, audit_log: audit, result:)

      process_failure_callback(file_set, audit) if should_call_failure_callback(audit)
    end

    def should_call_failure_callback(audit)
      audit.failed? && Hyrax.config.callback.set?(:after_fixity_check_failure)
    end

    def process_failure_callback(file_set, audit)
      Hyrax.config.callback.run(:after_fixity_check_failure,
                                file_set,
                                checksum_audit_log: audit, warn: false)
    end
end
# rubocop:enable Metrics/ClassLength
