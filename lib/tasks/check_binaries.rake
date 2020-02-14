# frozen_string_literal: true
namespace :curate do
  namespace :file_sets do
    desc "Check if files exist in s3"
    task check_binaries: :environment do
      file_set = ENV['file_set']
      bucket = ENV['bucket']

      if file_set.present?
        CheckBinariesJob.perform_now(bucket, file_set)
      else
        CheckBinariesJob.perform_later(bucket)
      end
    end
  end
end
