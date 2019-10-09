# frozen_string_literal: true
namespace :curate do
  desc "Langmuir preprocessing"
  task langmuir: :environment do
    langmuir_csv = ENV['CSV'] || ENV['csv'] || ''
    valid_args = \
      ARGV.length > 1 &&
      File.extname(langmuir_csv) == '.csv'
    if valid_args
      preprocessor = LangmuirPreprocessor.new(langmuir_csv)
      preprocessor.merge
      puts 'Rows processed: ' + preprocessor.record_count.to_s
      puts 'Processed file: ' + File.basename(preprocessor.processed_csv)
    else
      puts <<~HEREDOC
        Langmuir preprocessor

        USAGE:
        rake curate:langmuir csv=manifest.csv

        RETURNS:
        manifest-processed.csv in the samve folder as pull_list.csv

      HEREDOC
    end
  end
end
