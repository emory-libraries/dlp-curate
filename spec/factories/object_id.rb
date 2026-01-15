# frozen_string_literal: true
# [Hyrax-direct-copy-hyrax-v5.2.0] lib/hyrax/specs/shared_specs/factories/object_id.rb

# Defines a new sequence
FactoryBot.define do
  sequence :object_id do |n|
    "object_id_#{n}"
  end
end
