# frozen_string_literal: true
# Bulkrax v8.2.3 override: #perform

module Bulkrax
  class ScheduleRelationshipsJob < ApplicationJob
    def perform(importer_id:)
      importer = ::Bulkrax::Importer.find(importer_id)
      pending_num = importer.entries.left_outer_joins(:latest_status)
                            .where('bulkrax_statuses.status_message IS NULL ').count
      return reschedule(importer_id) unless pending_num.zero?

      ::ScheduleAssociateFilesetsWithWorkJob.perform_later(importer_id:) # Emory Addition
      importer.last_run.parents.each do |parent_id|
        Bulkrax.relationship_job_class.constantize.perform_later(parent_identifier: parent_id,
                                                                 importer_run_id:   importer.last_run.id)
      end
    end

    def reschedule(importer_id)
      ScheduleRelationshipsJob.set(wait: 5.minutes).perform_later(importer_id:)
      false
    end
  end
end
