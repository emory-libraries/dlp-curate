# frozen_string_literal: true

# Source: spec/factories/csv_import.rb, zizia v5.5.0
# https://github.com/curationexperts/zizia/blob/v5.5.0/spec/factories/csv_import.rb

FactoryBot.define do
  factory :csv_import, class: Zizia::CsvImport do
    id { 1 }
    user_id { 1 }
    created_at { Time.current }
    updated_at { Time.current }
    manifest { Rails.root.join('spec', 'fixtures', 'csv_imports', 'good', 'all_fields.csv') }
    fedora_collection_id { '1' }
    update_actor_stack { 'HyraxDefault' }
  end
end
