# frozen_string_literal: true
namespace :curate do
  namespace :file_sets do
    desc "Perform fixity checking on file_sets"
    task fixity_check: :environment do
      limit = ENV['limit'].to_i || FileSet.count # limit number of file_sets

      FileSet.all[0..limit].each do |file_set|
        Hyrax::FileSetFixityCheckService.new(file_set, max_days_between_fixity_checks: 90, initiating_user: "Curate system").fixity_check
      end
    end
  end
end
