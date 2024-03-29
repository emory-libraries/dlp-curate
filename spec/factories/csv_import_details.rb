# frozen_string_literal: true

# Source: spec/factories/csv_import_detail.rb, zizia v5.5.0
# https://github.com/curationexperts/zizia/blob/v5.5.0/spec/factories/csv_import_detail.rb

FactoryBot.define do
  factory :csv_import_detail, class: Zizia::CsvImportDetail do
    csv_import_id { 1 }
    created_at { Time.current }
    updated_at { Time.current }
    depositor_id { FactoryBot.build(:user).id }
    collection_id { '1' }
    batch_id { '1' }
    success_count { 1 }
    failure_count { 0 }
    deduplication_field { 'identifier' }
    update_actor_stack { 'HyraxMetadataOnly' }
  end
end
