# frozen_string_literal: true

module Curate
  # Migrates objects that store their locally minted NOID in +alternate_ids+
  # (which creates separate Fedora reference objects) to the new
  # +emory_persistent_id+ string property.
  #
  # For each object with alternate_ids present:
  #   1. Copies the first alternate_id value into emory_persistent_id
  #   2. Clears alternate_ids
  #   3. Saves and re-indexes the resource
  class ValkyrieObjectRemediationService
    attr_reader :logger

    def initialize(logger: Rails.logger)
      @logger = logger
    end

    def migrate_alternate_ids_to_emory_persistent_id
      objects = Hyrax.query_service.custom_queries.find_all_objects_with_alternate_ids_present
      logger.info("[Remediation] Found #{objects.size} objects with alternate_ids to migrate")

      migrated = 0
      skipped  = 0
      errored  = 0

      objects.each do |resource|
        result = migrate_single_resource(resource)
        if result == :skipped
          skipped += 1
        else
          migrated += 1
        end
      rescue StandardError => e
        errored += 1
        logger.error("[Remediation] Error migrating #{resource.id}: #{e.message}")
      end

      logger.info("[Remediation] Complete: migrated=#{migrated}, skipped=#{skipped}, errored=#{errored}")
      { migrated:, skipped:, errored: }
    end

    private

      def migrate_single_resource(resource)
        alt_id = resource.alternate_ids.first&.to_s
        unless alt_id.present?
          logger.info("[Remediation] #{resource.id}: no alternate_ids value, skipping")
          return :skipped
        end

        if resource.respond_to?(:emory_persistent_id) && resource.emory_persistent_id.present?
          logger.info("[Remediation] #{resource.id}: emory_persistent_id already set (#{resource.emory_persistent_id}), skipping")
          return :skipped
        end

        logger.info("[Remediation] #{resource.id}: migrating alternate_id #{alt_id} → emory_persistent_id")
        resource.emory_persistent_id = alt_id
        resource.alternate_ids = []

        saved = Hyrax.persister.save(resource:)
        Hyrax.index_adapter.save(resource: saved)
        :migrated
      end
  end
end
