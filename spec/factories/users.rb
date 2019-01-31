FactoryBot.define do
  factory :user do
    uid { FFaker::Internet.user_name }
    display_name { FFaker::Name.name }
    email { FFaker::Internet.email }

    transient do
      # Allow for custom groups when a user is instantiated.
      # @example FactoryBot.create(:user, groups: 'admin')
      groups []
    end

    after(:build) do |user, evaluator|
      # In case we have the instance but it has not been persisted
      ::RSpec::Mocks.allow_message(user, :groups).and_return(Array.wrap(evaluator.groups))
      # Given that we are stubbing the class, we need to allow for the original to be called
      ::RSpec::Mocks.allow_message(user.class.group_service, :fetch_groups).and_call_original
      # We need to ensure that each instantiation of the admin user behaves as expected.
      # This resolves the issue of both the created object being used as well as re-finding the created object.
      ::RSpec::Mocks.allow_message(user.class.group_service, :fetch_groups).with(user: user).and_return(Array.wrap(evaluator.groups))
    end

    factory :admin do
      groups { ['admin'] }

      after(:create) do |user|
        role = Role.find_or_create_by(name: 'admin')
        role.users << user
        role.save
      end
    end

    trait :guest do
      guest true
    end
  end
end
