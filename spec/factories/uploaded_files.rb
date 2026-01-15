# frozen_string_literal: true
# [Hyrax-override-hyrax-v5.2.0] lib/hyrax/specs/shared_specs/factories/uploaded_files.rb

FactoryBot.define do
  factory :uploaded_file, class: Hyrax::UploadedFile do
    user
  end
end
