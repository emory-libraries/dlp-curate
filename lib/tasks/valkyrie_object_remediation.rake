# frozen_string_literal: true

namespace :curate do
  namespace :valkyrie_object_remediation do
    desc "Migrate alternate_ids to emory_persistent_id string property"
    task migrate_alternate_ids_to_emory_persistent_id: :environment do
      service = Curate::ValkyrieObjectRemediationService.new(logger: Logger.new($stdout))
      result = service.migrate_alternate_ids_to_emory_persistent_id
      puts "Done. migrated=#{result[:migrated]}, skipped=#{result[:skipped]}, errored=#{result[:errored]}"
    end

    desc "Add missing Validation and Policy Assignment preservation events to Valkyrie works (DRY_RUN=true to preview)"
    task backfill_work_creation_events: :environment do
      dry_run = ENV['DRY_RUN'] == 'true'
      service = Curate::WorkCreationEventsBackfillService.new(logger: Logger.new($stdout), dry_run:)
      result = service.backfill
      puts "Done#{' (dry run)' if dry_run}. backfilled=#{result[:backfilled]}, skipped=#{result[:skipped]}, errored=#{result[:errored]}"
    end
  end
end
