# frozen_string_literal: true
# Bulkrax v9.3.5 override: #perform

module Bulkrax
  class MissingParentError < ::StandardError; end

  class ImportFileSetJob < ApplicationJob
    include DynamicRecordLookup

    queue_as Bulkrax.config.ingest_queue_name

    attr_reader :importer_run_id

    def perform(entry_id, importer_run_id)
      @importer_run_id = importer_run_id
      entry = Entry.find(entry_id)
      # e.g. "parents" or "parents_1"
      parent_identifier = (entry.raw_metadata[entry.related_parents_raw_mapping] || entry.raw_metadata["#{entry.related_parents_raw_mapping}_1"])&.strip

      begin
        validate_parent!(parent_identifier)
      rescue MissingParentError => e
        handle_retry(entry, importer_run_id, e)
        return
      end

      entry.build
      if entry.succeeded?
        # rubocop:disable Rails/SkipsModelValidations
        ImporterRun.increment_counter(:processed_records, importer_run_id)
        ImporterRun.increment_counter(:processed_file_sets, importer_run_id)
      else
        ImporterRun.increment_counter(:failed_records, importer_run_id)
        ImporterRun.increment_counter(:failed_file_sets, importer_run_id)
        # Emory Addition Below: We want to retry on failed entry builds, too
        handle_retry(entry, importer_run_id, entry.current_status.error_message)
        return
        # End of Emory Addition
        # rubocop:enable Rails/SkipsModelValidations
      end
      ImporterRun.decrement_counter(:enqueued_records, importer_run_id) unless ImporterRun.find(importer_run_id).enqueued_records <= 0 # rubocop:disable Rails/SkipsModelValidations
      entry.save!
      entry.importer.current_run = ImporterRun.find(importer_run_id)
      entry.importer.record_status
    end

    private

      attr_reader :parent_record

      def validate_parent!(parent_identifier)
        # if parent_identifier is missing, it will be caught by #validate_presence_of_parent!
        return if parent_identifier.blank?

        find_parent_record(parent_identifier)
        check_parent_is_a_work!(parent_identifier)
      end

      def check_parent_is_a_work!(parent_identifier)
        case parent_record
        when Bulkrax.collection_model_class, Bulkrax.file_model_class
          error_msg = %(A record with the ID "#{parent_identifier}" was found, but it was a #{parent_record.class}, which is not an valid/available work type)
          raise ::StandardError, error_msg
        end
      end

      def find_parent_record(parent_identifier)
        _, @parent_record = find_record(parent_identifier, importer_run_id)
        raise MissingParentError, %(Unable to find a record with the identifier "#{parent_identifier}") unless parent_record
      end

      def handle_retry(entry, importer_run_id, e)
        entry.import_attempts += 1
        entry.save!
        # Emory Alteration: we set our own retry count and wait times.
        if entry.import_attempts < ENV.fetch("IMPORT_FILE_SET_RETRIES", 8).to_i
          ImportFileSetJob.set(wait: jittered_wait_for_retries(attempts: entry.import_attempts)).perform_later(entry.id, importer_run_id)
        # End of Emory Alteration
        else
          ImporterRun.decrement_counter(:enqueued_records, importer_run_id) # rubocop:disable Rails/SkipsModelValidations
          entry.set_status_info(e)
        end
      end

      # Emory Addition: we shouldn't wait many minutes to retry again.
      def jittered_wait_for_retries(attempts:)
        desired_wait_for_application = ENV.fetch("IMPORT_FILE_SET_WAIT", 30).to_i
        pure_wait_in_seconds = attempts * desired_wait_for_application
        jitter_value_in_seconds = rand(1..desired_wait_for_application)

        pure_wait_in_seconds + jitter_value_in_seconds
      end
    # End of Emory Addition
  end
end
