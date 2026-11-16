# frozen_string_literal: true

module Hyrax
  # [Hyrax-override-hyrax-v5.2.0] Introduces initiating user for preservation events
  # created by the ensuing fixity checks]
  ##
  # This class runs fixity checks on a {FileSetBehavior}, potentially on multiple
  # files each with multiple versions in the +FileSet+.
  #
  # The fixity check itself is performed by {FixityCheckJob}, which
  # just uses the fedora service to ask for fixity verification.
  # The outcome will be some created {ChecksumAuditLog} (ActiveRecord)
  # objects, recording the checks and their results.
  #
  # By default this runs the checks async using +ActiveJob+, so
  # returns no useful info -- the checks are still going Use
  # {ChecksumAuditLog.latest_for_file_set_id} to retrieve the latest
  # machine-readable checks.
  #
  # But if you initialize with +async_jobs: false+, checks will be done
  # blocking in foreground, and you can get back the {ChecksumAuditLog}
  # records created.
  #
  # It will only run fixity checks if there are not recent
  # {ChecksumAuditLog}s on record. "recent" is defined by
  # +max_days_between_fixity_checks+ arg, which defaults to configured
  # {Hyrax::Configuration#max_days_between_fixity_checks}
  class FileSetFixityCheckService
    attr_reader :id, :latest_version_only,
                :async_jobs, :max_days_between_fixity_checks

    # @param file_set [ActiveFedora::Base, Hyrax::Resource, String] file_set or its ID
    # @param async_jobs [Boolean] Run actual fixity checks in background. Default true.
    # @param max_days_between_fixity_checks [int] if an existing fixity check is
    #   recorded within this window, no new one will be created. Default
    #   {Hyrax::Configuration#max_days_between_fixity_checks}. Set to -1 to force check.
    # @param latest_version_only [Boolean]. Check only latest version instead of all
    #   versions. Default false. (AF-only, ignored for Valkyrie)
    def initialize(file_set,
                   async_jobs: true,
                   max_days_between_fixity_checks: Hyrax.config.max_days_between_fixity_checks,
                   latest_version_only: false,
                   initiating_user:)
      @max_days_between_fixity_checks = max_days_between_fixity_checks || 0
      @async_jobs = async_jobs
      @latest_version_only = latest_version_only
      @initiating_user = initiating_user
      if file_set.is_a?(String)
        @id = file_set
      else
        @id = file_set.id.to_s
        @file_set = file_set
      end
    end

    # Fixity checks each version of each file if it hasn't been checked recently.
    # For AF file sets, checks all file versions (or latest only if configured).
    # For Valkyrie file sets, checks the original file via checksum comparison.
    #
    # If async_jobs is false, returns the set of most recent fixity check
    # status for each version of the content file(s). As a hash keyed by file_id,
    # values arrays of possibly multiple version checks.
    #
    # If async_jobs is true (default), just returns nil, stuff is still going on.
    def fixity_check
      if file_set.is_a?(Hyrax::Resource)
        fixity_check_valkyrie
      else
        fixity_check_af
      end
    end

    private

      # --- Valkyrie path ---

      def fixity_check_valkyrie
        fm = original_file_metadata
        return if fm.blank?

        checked_uri = fm.file_identifier.to_s
        latest_fixity_check = ChecksumAuditLog.logs_for(id, checked_uri:).first
        return latest_fixity_check unless needs_fixity_check?(latest_fixity_check)

        if async_jobs
          FixityCheckJob.perform_later(file_set_id: id, initiating_user: @initiating_user)
        else
          FixityCheckJob.perform_now(file_set_id: id, initiating_user: @initiating_user)
        end
      end

      def original_file_metadata
        Hyrax.custom_queries
             .find_many_file_metadata_by_use(resource: file_set, use: Hyrax::FileMetadata::Use::ORIGINAL_FILE)
             .first
      end

      # --- ActiveFedora path ---

      def fixity_check_af
        results = file_set.files.collect { |f| fixity_check_file(f) }

        return if async_jobs

        results.flatten.group_by(&:file_id)
      end

      # Retrieve or generate the fixity check for a file
      # (all versions are checked for versioned files unless latest_version_only set)
      # @param [ActiveFedora::File] file to fixity check
      def fixity_check_file(file)
        versions = file.has_versions? ? file.versions.all : [file]
        versions = [versions.max_by(&:created)] if file.has_versions? && latest_version_only
        versions.collect { |v| fixity_check_file_version(file.id, v.uri.to_s) }.flatten
      end

      # Retrieve or generate the fixity check for a specific version of a file
      # @param [String] file_id used to find the file within its parent object (usually "original_file")
      # @param [String] version_uri the version to be fixity checked (or the file uri for non-versioned files)
      def fixity_check_file_version(file_id, version_uri)
        latest_fixity_check = ChecksumAuditLog.logs_for(file_set.id, checked_uri: version_uri).first
        return latest_fixity_check unless needs_fixity_check?(latest_fixity_check)

        if async_jobs
          FixityCheckJob.perform_later(version_uri.to_s, file_set_id: file_set.id, file_id:, initiating_user: @initiating_user)
        else
          FixityCheckJob.perform_now(version_uri.to_s, file_set_id: file_set.id, file_id:, initiating_user: @initiating_user)
        end
      end

      # --- Shared helpers ---

      # Check if time since the last fixity check is greater than the maximum days allowed between fixity checks
      # @param [ChecksumAuditLog] latest_fixity_check the most recent fixity check
      def needs_fixity_check?(latest_fixity_check)
        return true unless latest_fixity_check
        unless latest_fixity_check.updated_at
          logger.warn "***FIXITY*** problem with fixity check log! Latest Fixity check is not nil, " \
                      "but updated_at is not set #{latest_fixity_check}"
          return true
        end
        days_since_last_fixity_check(latest_fixity_check) >= max_days_between_fixity_checks
      end

      # Return the number of days since the latest fixity check
      # @param [ChecksumAuditLog] latest_fixity_check the most recent fixity check
      def days_since_last_fixity_check(latest_fixity_check)
        (DateTime.current - latest_fixity_check.updated_at.to_date).to_i
      end

      def file_set
        @file_set ||= find_file_set
      end

      def find_file_set
        if Hyrax.config.valkyrie_transition?
          Hyrax.query_service.find_by(id:)
        else
          ::FileSet.find(id)
        end
      end
  end
end
