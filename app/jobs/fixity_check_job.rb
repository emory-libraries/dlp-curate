# frozen_string_literal: true
# [Hyrax-overwrite-v3.4.1]
# Adds fixity_check preservation_event

require 'sidekiq-limit_fetch'

class FixityCheckJob < Hyrax::ApplicationJob
  queue_as :fixity_check_job
  include PreservationEvents
  # A Job class that runs a fixity check (using Hyrax.config.fixity_service)
  # which contacts fedora and requests a fixity check), and stores the results
  # in an ActiveRecord ChecksumAuditLog row. It also prunes old ChecksumAuditLog
  # rows after creating a new one, to keep old ones you don't care about from
  # filling up your db.
  #
  # The uri passed in is a fedora URI that fedora can run fixity check on.
  # It's normally a version URI like:
  #     http://localhost:8983/fedora/rest/test/a/b/c/abcxyz/content/fcr:versions/version1
  #
  # But could theoretically be any URI fedora can fixity check on, like a file uri:
  #     http://localhost:8983/fedora/rest/test/a/b/c/abcxyz/content
  #
  # The file_set_id and file_id are used only for logging context in the
  # ChecksumAuditLog, and determining what old ChecksumAuditLogs can
  # be pruned.
  #
  # If calling async as a background job, return value is irrelevant, but
  # if calling sync with `perform_now`, returns the ChecksumAuditLog
  # record recording the check.
  #
  # @param uri [String] uri - of the specific file/version to fixity check
  # @param file_set_id [FileSet] the id for FileSet parent object of URI being checked.
  # @param file_id [String] File#id, used for logging/reporting.
  def perform(uri, file_set_id:, file_id:, initiating_user:)
    event_start = DateTime.current
    run_check(file_set_id, file_id, uri).tap do |audit|
      result   = audit.failed? ? :failure : :success
      file_set = ::FileSet.find(file_set_id)

      announce_fixity_check_results(file_set, audit, result)
      file_set_preservation_event(audit.passed, file_set_id, file_id, event_start, initiating_user)
    end
  end

  private

    ##
    # @api private
    def run_check(file_set_id, file_id, uri)
      service = fixity_service_for(id: uri)
      expected_result = service.expected_message_digest

      ChecksumAuditLog.create_and_prune!(passed: service.check, file_set_id: file_set_id, checked_uri: uri.to_s, file_id: file_id, expected_result: expected_result)
    rescue Hyrax::Fixity::MissingContentError
      ChecksumAuditLog.create_and_prune!(passed: false, file_set_id: file_set_id, checked_uri: uri.to_s, file_id: file_id, expected_result: expected_result)
    end

    ##
    # @api private
    # @return [Class]
    def fixity_service_for(id:)
      Hyrax.config.fixity_service.new(id)
    end

    def file_set_preservation_event(log, file_set_id, file_id, event_start, initiating_user)
      @logger = Logger.new(STDOUT)
      fixity_file_set = ::FileSet.find(file_set_id)
      fixity_file = Hydra::PCDM::File.find(file_id)
      event = { 'type' => 'Fixity Check', 'start' => event_start, 'software_version' => 'Fedora v4.7.5', 'user' => initiating_user }
      if log == true
        event['outcome'] = 'Success'
        event['details'] = "Fixity intact for file: #{fixity_file&.original_name}: sha1:#{fixity_file&.checksum&.value}"
        @logger.info "Ran fixity check successfully on #{fixity_file&.original_name}"
      else
        event['outcome'] = 'Failure'
        event['details'] = "Fixity check failed for: #{fixity_file&.original_name}: sha1:#{fixity_file&.checksum&.value}"
        @logger.error "Fixity check failure: Fixity failed for #{fixity_file&.original_name}"
      end
      create_preservation_event(fixity_file_set, event)
    end

    def announce_fixity_check_results(file_set, audit, result)
      Hyrax.publisher.publish('file.set.audited', file_set: file_set, audit_log: audit, result: result)

      # @todo remove this callback call for Hyrax 4.0.0
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
