# frozen_string_literal: true
namespace :curate do
  namespace :jhove do
    desc "Perform jhove checkup on files in a collection"
    task jhove_check: :environment do
      directory = ENV['base_dir']
      jhove_path = ENV['jhove_path'] || 'opt/jhove/jhove'
      JhoveCheckupJob.perform_later(jhove_path, directory)
    end
  end
end
