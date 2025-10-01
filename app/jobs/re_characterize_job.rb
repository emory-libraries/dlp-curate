# frozen_string_literal: true

class ReCharacterizeJob < Hyrax::ApplicationJob
  def perform(file_set:, user: nil)
    repository_file = file_set.pulled_preservation_master_file

    ReCharacterizationService.empty_out_characterization(repository_file)
    CharacterizeJob.perform_later(file_set, repository_file.id, "", user)
  end
end
