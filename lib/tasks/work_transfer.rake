# frozen_string_literal: true

namespace :curate do
  namespace :works do
    desc "Transfer works from one collection to another"
    task transfer_works: :environment do
      import_col = ENV['import_col']
      true_col = ENV['true_col']
      TransferWorksJob.perform_later(import_col, true_col)
    end
  end
end
