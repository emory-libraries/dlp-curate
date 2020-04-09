# frozen_string_literal: true

namespace :curate do
  namespace :objects do
    desc 'Reindex objects'
    task reindex: [:environment] do
      csv_file = Rails.root.join('config', 'reindex', 'reindex_objects.csv')
      CSV.foreach(csv_file, headers: true) do |row|
        r = row.to_h
        ReindexObjectsJob.perform_later(r['id'])
      end
    end
  end
end
