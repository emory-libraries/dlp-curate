# frozen_string_literal: true

module Curate
  # Adds the work-level Validation and Policy Assignment preservation events to
  # Valkyrie works created before those events were attached at creation.
  #
  # Only works stored natively in Valkyrie (Fedora 6+) are changed; saving an
  # AF work through the Valkyrie persister would migrate it, and AF works
  # already get these events from Hyrax::Actors::CurateGenericWorkActor.
  class WorkCreationEventsBackfillService
    include PreservationEvents

    CREATION_EVENT_TYPES = ['Validation', 'Policy Assignment'].freeze

    attr_reader :logger, :dry_run

    def initialize(logger: Rails.logger, dry_run: false)
      @logger = logger
      @dry_run = dry_run
    end

    def backfill
      counters = { backfilled: 0, skipped: 0, errored: 0 }
      work_ids.each { |id| process_work(id, counters) }
      logger.info("[WorkCreationEventsBackfill] #{'(dry run) ' if dry_run}Complete: #{counters.map { |k, v| "#{k}=#{v}" }.join(', ')}")
      counters
    end

    private

      def work_ids
        Hyrax::SolrService.query('has_model_ssim:CurateGenericWork', fl: 'id', rows: 1_000_000).map { |doc| doc['id'] }
      end

      def process_work(id, counters)
        counters[backfill_work(id)] += 1
      rescue StandardError => e
        counters[:errored] += 1
        logger.error("[WorkCreationEventsBackfill] Error backfilling #{id}: #{e.message}")
      end

      def backfill_work(id)
        return skip(id, 'not a native Valkyrie work') unless native_valkyrie_work?(id)

        work = Hyrax.query_service.find_by(id:)
        missing = CREATION_EVENT_TYPES - work.preservation_event.flat_map { |event| Array(event.event_type) }
        return skip(id, 'already has work creation events') if missing.empty?

        logger.info("[WorkCreationEventsBackfill] #{id}: #{dry_run ? 'would add' : 'adding'} #{missing.join(', ')}")
        add_events(work, missing) unless dry_run
        :backfilled
      end

      def native_valkyrie_work?(id)
        Valkyrie::MetadataAdapter.find(:fedora_metadata).query_service.find_by(id:)
        true
      rescue Valkyrie::Persistence::ObjectNotFoundError
        false
      end

      def add_events(work, missing)
        event_start = work.date_uploaded || work.created_at || DateTime.current
        events = missing.map { |type| creation_event(type, work, event_start) }
        work.preservation_event += events.map { |event| persist_valkyrie_preservation_event(event) }
        saved = Hyrax.persister.save(resource: work)
        Hyrax.index_adapter.save(resource: saved)
      end

      def creation_event(type, work, event_start)
        if type == 'Validation'
          work_creation(event_start:, user_email: work.depositor)
        else
          work_policy(event_start:, visibility: work.visibility, user_email: work.depositor)
        end
      end

      def skip(id, reason)
        logger.info("[WorkCreationEventsBackfill] #{id}: #{reason}, skipping")
        :skipped
      end
  end
end
