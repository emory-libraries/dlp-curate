# frozen_string_literal: true
namespace :curate do
  namespace :file_sets do
    desc "Process AWS Fixity Checks' Preservation Events"
    task aws_fixity_check: :environment do
      csv = ENV['csv']
      valid_args = File.extname(csv) == '.csv'

      if valid_args
        ProcessAwsFixityPreservationEventsJob.perform_later(csv)
        puts "Queued background jobs to process AWS Fixity preservation events for #{csv}"
      else
        abort "ERROR: file attached must be a CSV file."
      end
    end
  end
end
