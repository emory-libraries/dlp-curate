# frozen_string_literal: true

module Curate
  # Gives existing works the sharing of their collection (see CollectionSharingService),
  # for works deposited before it was applied at deposit: Valkyrie works created in the
  # UI and works added to a collection by a Bulkrax import.
  #
  # Only adds grants. Works still stored in AF (Fedora 4) are updated through AF, so the
  # backfill does not migrate them.
  class CollectionSharingBackfillService
    attr_reader :logger, :dry_run, :collection_id

    # @param collection_id [String, nil] limit the backfill to the works of one collection
    def initialize(logger: Rails.logger, dry_run: false, collection_id: nil)
      @logger = logger
      @dry_run = dry_run
      @collection_id = collection_id
    end

    def backfill
      counters = { shared: 0, unchanged: 0, errored: 0 }
      work_ids.each { |id| process_work(id, counters) }
      logger.info("[CollectionSharingBackfill] #{'(dry run) ' if dry_run}Complete: #{counters.map { |k, v| "#{k}=#{v}" }.join(', ')}")
      counters
    end

    private

      def work_ids
        query = 'has_model_ssim:CurateGenericWork AND member_of_collection_ids_ssim:*'
        query = "has_model_ssim:CurateGenericWork AND member_of_collection_ids_ssim:#{RSolr.solr_escape(collection_id)}" if collection_id
        Hyrax::SolrService.query(query, fl: 'id', rows: 1_000_000).map { |doc| doc['id'] }
      end

      def process_work(id, counters)
        changed = CollectionSharingService.share_with_saved(load_work(id), dry_run:)
        if changed.empty?
          counters[:unchanged] += 1
        else
          counters[:shared] += 1
          logger.info("[CollectionSharingBackfill] #{id}: #{dry_run ? 'would share' : 'shared'} with #{changed.size} object(s) (work and FileSets)")
        end
      rescue StandardError => e
        counters[:errored] += 1
        logger.error("[CollectionSharingBackfill] Error sharing with #{id}: #{e.message}")
      end

      def load_work(id)
        Valkyrie::MetadataAdapter.find(:fedora_metadata).query_service.find_by(id:)
      rescue Valkyrie::Persistence::ObjectNotFoundError
        CurateGenericWork.find(id)
      end
  end
end
