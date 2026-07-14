# frozen_string_literal: true
# [Hyrax-direct-copy-hyrax-v5.2.0] lib/hyrax/specs/shared_specs/factories/permission_template_accesses.rb

FactoryBot.define do
  factory :permission_template_access, class: Hyrax::PermissionTemplateAccess do
    permission_template
    trait :manage do
      access { 'manage' }
    end

    trait :deposit do
      access { 'deposit' }
    end

    trait :view do
      access { 'view' }
    end
  end
end
