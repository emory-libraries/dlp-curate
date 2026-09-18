# frozen_string_literal: true

namespace :curate do
  namespace :valkyrie_object_remediation do
    desc "Migrate alternate_ids to emory_persistent_id string property"
    task migrate_alternate_ids_to_emory_persistent_id: :environment do
      service = Curate::ValkyrieObjectRemediationService.new(logger: Logger.new($stdout))
      result = service.migrate_alternate_ids_to_emory_persistent_id
      puts "Done. migrated=#{result[:migrated]}, skipped=#{result[:skipped]}, errored=#{result[:errored]}"
    end
  end
end
