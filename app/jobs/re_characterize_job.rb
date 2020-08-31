# frozen_string_literal: true

class ReCharacterizeJob < Hyrax::ApplicationJob
  def perform(file_set:, user: nil)
    repository_file = file_set.public_send(:preservation_master_file)

    ReCharacterizationService.new(repository_file).empty_characterization
    CharacterizeJob.perform_later(file_set, repository_file.id, user)
  end
end
