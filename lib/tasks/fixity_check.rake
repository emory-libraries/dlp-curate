# frozen_string_literal: true
namespace :curate do
  namespace :file_sets do
    desc "Perform fixity checking on file_sets"
    task fixity_check: :environment do
      count_response = Blacklight.default_index.connection.get 'select', params: { q: "has_model_ssim:FileSet", rows: 0 }
      total_count = count_response["response"]["numFound"]
      limit = ENV['limit'].present? ? ENV['limit'].to_i : total_count

      response = Blacklight.default_index.connection.get 'select', params: { q: "has_model_ssim:FileSet", rows: limit, fl: "id" }
      file_set_ids = response["response"]["docs"].pluck("id")

      file_set_ids.each do |file_set_id|
        file_set = if Hyrax.config.valkyrie_transition?
                     Hyrax.query_service.find_by(id: file_set_id)
                   else
                     FileSet.find(file_set_id)
                   end
        Hyrax::FileSetFixityCheckService.new(file_set, max_days_between_fixity_checks: 90, initiating_user: "Curate system").fixity_check
      end
    end
  end
end
