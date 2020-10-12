# frozen_string_literal: true
namespace :curate do
  namespace :file_sets do
    desc "Perform fixity checking on file_sets"
    task fixity_check: :environment do
      limit = ENV['limit'].present? ? ENV['limit'].to_i : FileSet.count # limit number of file_sets
      response = Blacklight.default_index.connection.get 'select', params: { q: "has_model_ssim:FileSet", rows: limit, fl: "id" }
      file_set_ids = response["response"]["docs"].pluck("id")

      file_set_ids.each do |file_set_id|
        Hyrax::FileSetFixityCheckService.new(FileSet.find(file_set_id), max_days_between_fixity_checks: 90, initiating_user: "Curate system").fixity_check
      end
    end
  end
end
