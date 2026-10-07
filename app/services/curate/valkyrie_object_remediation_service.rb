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
      counters = { migrated: 0, skipped: 0, errored: 0 }
      objects.each { |resource| process_resource(resource, counters) }
      logger.info("[Remediation] Complete: #{counters.map { |k, v| "#{k}=#{v}" }.join(', ')}")
      counters
    end

    private

      def process_resource(resource, counters)
        result = migrate_single_resource(resource)
        counters[result] += 1
      rescue StandardError => e
        counters[:errored] += 1
        logger.error("[Remediation] Error migrating #{resource.id}: #{e.message}")
      end

      def migrate_single_resource(resource)
        alt_id = resource.alternate_ids.first&.to_s
        return skip_resource(resource, "no alternate_ids value") if alt_id.blank?
        return skip_resource(resource, "emory_persistent_id already set (#{resource.emory_persistent_id})") if already_migrated?(resource)

        persist_migration(resource, alt_id)
      end

      def skip_resource(resource, reason)
        logger.info("[Remediation] #{resource.id}: #{reason}, skipping")
        :skipped
      end

      def already_migrated?(resource)
        resource.respond_to?(:emory_persistent_id) && resource.emory_persistent_id.present?
      end

      def persist_migration(resource, alt_id)
        logger.info("[Remediation] #{resource.id}: migrating alternate_id #{alt_id} → emory_persistent_id")
        resource.emory_persistent_id = alt_id
        resource.alternate_ids = []
        saved = Hyrax.persister.save(resource:)
        Hyrax.index_adapter.save(resource: saved)
        :migrated
      end
  end
end
