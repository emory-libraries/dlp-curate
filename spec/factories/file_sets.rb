# frozen_string_literal: true
# [Hyrax-override-hyrax-v5.2.0] lib/hyrax/specs/shared_specs/factories/file_sets.rb

FactoryBot.define do
  factory :file_set do
    transient do
      user { FactoryBot.build(:user) }
      title { nil }
      content { nil }
    end
    after(:build) do |fs, evaluator|
      fs.apply_depositor_metadata evaluator.user.user_key
      fs.title = evaluator.title
    end

    after(:create) do |file, evaluator|
      Hydra::Works::UploadFileToFileSet.call(file, evaluator.content) if evaluator.content
    end

    trait :public do
      read_groups { ["public"] }
    end

    trait :registered do
      read_groups { ["registered"] }
    end

    factory :file_with_work do
      after(:build) do |file, _evaluator|
        file.title = ['testfile']
      end
      after(:create) do |file, evaluator|
        Hydra::Works::UploadFileToFileSet.call(file, evaluator.content) if evaluator.content
        FactoryBot.create(:work, user: evaluator.user).members << file
      end
    end
  end
end
