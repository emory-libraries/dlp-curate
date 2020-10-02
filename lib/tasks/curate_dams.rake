# frozen_string_literal: true
namespace :curate do
  desc "DAMS preprocessing"
  task dams: :environment do
    dams_csv = ENV['CSV'] || ENV['csv'] || ''
    valid_args = \
      ARGV.length > 1 &&
      File.extname(dams_csv) == '.csv'
    if valid_args
      preprocessor = DamsPreprocessor.new(dams_csv)
      preprocessor.merge
      puts 'Rows processed: ' + preprocessor.record_count.to_s
      puts 'Processed file: ' + File.basename(preprocessor.processed_csv)
    else
      puts <<~HEREDOC
        DAMS preprocessor

        USAGE:
        rake curate:dams csv=manifest.csv

        RETURNS:
        manifest-processed.csv in the same folder as manifest.csv

      HEREDOC
    end
  end
end
