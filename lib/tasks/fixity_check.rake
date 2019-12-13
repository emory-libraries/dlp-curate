# frozen_string_literal: true
namespace :curate do
  namespace :file_sets do
    desc "Perform fixity checking on file_sets"
    task fixity_check: :environment do
      FileSet.all.each do |file_set|
        Hyrax::FileSetFixityCheckService.new(file_set, max_days_between_fixity_checks: 90).fixity_check
      end
    end
  end
end
