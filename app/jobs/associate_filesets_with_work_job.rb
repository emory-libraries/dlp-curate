# frozen_string_literal: true
# NOTE: We should delete this and remove its call in `ScheduleRelationshipsJob` when we move to Valkyrized imports.

class AssociateFilesetsWithWorkJob < Hyrax::ApplicationJob
  include AssociateFilesetsWithWorks
  queue_as :import

  def perform(importer:)
    file_set_entries = pull_file_set_entries(importer:)
    parents = pull_parents(file_set_entries:)

    process_file_sets(parents:, file_set_entries:)
  end
end
