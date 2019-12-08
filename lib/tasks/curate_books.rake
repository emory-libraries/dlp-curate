# frozen_string_literal: true
namespace :curate do
  desc "Book preprocessing"
  task books: :environment do
    pull_list_csv = ENV['CSV'] || ENV['csv'] || ''
    alma_xml = ENV['XML'] || ENV['xml'] || ''
    replacement_path = ENV['REPL'] || ENV['repl'] || ''
    digitization = ENV['MAP'] || ENV['map'] || ''
    valid_args = \
      ARGV.length > 4 &&
      File.extname(pull_list_csv) == '.csv' &&
      File.extname(alma_xml) == '.xml' &&
      ['kirtas', 'limb'].include?(digitization.downcase)
    if valid_args
      preprocessor = YellowbackPreprocessor.new(pull_list_csv, alma_xml, replacement_path, digitization.downcase.to_sym)
      preprocessor.merge
      # puts 'Rows processed: ' + preprocessor.record_count.to_s
      puts 'Processed file: ' + File.basename(preprocessor.processed_csv)
    else
      puts <<~HEREDOC
        Book preprocessor (Kirtas & LIMB digitization)

        USAGE:
        rake curate:kirtas csv=pull_list.csv xml=alma.xml repl='path/to/substitute-for-Volumes' map={kirtas|limb}

        RETURNS:
        pull-list-merged.csv in the samve folder as pull-list.csv

      HEREDOC
    end
  end
end
