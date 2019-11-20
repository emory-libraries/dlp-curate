# frozen_string_literal: true
namespace :curate do
  desc "Kirtas preprocessing"
  task kirtas: :environment do
    pull_list_csv = ENV['CSV'] || ENV['csv'] || ''
    alma_xml = ENV['XML'] || ENV['xml'] || ''
    valid_args = \
      ARGV.length > 2 &&
      File.extname(pull_list_csv) == '.csv' &&
      File.extname(alma_xml) == '.xml'
    if valid_args
      preprocessor = YellowbackPreprocessor.new(pull_list_csv, alma_xml)
      preprocessor.merge
      # puts 'Rows processed: ' + preprocessor.record_count.to_s
      puts 'Processed file: ' + File.basename(preprocessor.processed_csv)
    else
      puts <<~HEREDOC
        Kirtas preprocessor

        USAGE:
        rake curate:kirtas csv=pull_list.csv xml=alma.xml

        RETURNS:
        pull-list-merged.csv in the samve folder as pull-list.csv

      HEREDOC
    end
  end
end
