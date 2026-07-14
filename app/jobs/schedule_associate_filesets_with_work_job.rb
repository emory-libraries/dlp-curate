# frozen_string_literal: true

class ScheduleAssociateFilesetsWithWorkJob < Hyrax::ApplicationJob
  include AssociateFilesetsWithWorks
  queue_as :import

  def perform(importer_id:)
    importer = Bulkrax::Importer.find(importer_id)
    file_set_entries = pull_file_set_entries(importer:)

    return reschedule(importer_id:) unless file_set_entries.present? && file_set_entry_parents_present?(file_set_entries:)

    AssociateFilesetsWithWorkJob.perform_later(importer:)
  end

  def reschedule(importer_id:)
    ScheduleAssociateFilesetsWithWorkJob.set(wait: 3.minutes).perform_later(importer_id:)
    false
  end
end
