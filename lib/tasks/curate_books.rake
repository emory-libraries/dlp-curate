# frozen_string_literal: true
namespace :curate do
  desc "Book preprocessing"
  task books: :environment do
    pull_list_csv = ENV['CSV'] || ENV['csv'] || ''
    alma_xml = ENV['XML'] || ENV['xml'] || ''
    replacement_path = ENV['REPL'] || ENV['repl'] || ''
    digitization = ENV['MAP'] || ENV['map'] || ''
    start_page = ENV['BASE'] || ENV['base'] || 1
    valid_args = \
      ARGV.length > 4 &&
      File.extname(pull_list_csv) == '.csv' &&
      File.extname(alma_xml) == '.xml' &&
      ['kirtas', 'limb'].include?(digitization.downcase)
    if valid_args
      preprocessor = YellowbackPreprocessor.new(pull_list_csv, alma_xml, replacement_path, digitization.downcase.to_sym, start_page.to_i)
      preprocessor.merge
      puts 'Processed file: ' + File.basename(preprocessor.processed_csv)
    else
      puts <<~HEREDOC
        Book preprocessor (Kirtas & LIMB digitization)

        USAGE:
        rake curate:books csv=pull_list.csv xml=alma.xml repl='path/to/substitute-for-Volumes' map={kirtas|limb} base={1|0}

        RETURNS:
        pull-list-merged.csv in the same folder as pull-list.csv
      HEREDOC
    end
  end
end
