require 'rails_helper'

module Test
  TypeValidatable = Struct.new(:created_at) do
    include ActiveModel::Validations
    validates :created_at, type: Date
  end
end

describe TypeValidator, type: :model do
  subject(:work) { described_class.new }
  subject(:work) { Test::TypeValidatable.new Date.new(2018, 1, 12) }

  context 'not a date' do
    it 'is invalid' do
      work.created_at = 'test'
      work.valid?
      expect(work.errors[:email]).to match_array('is not of class Date')
    end
  end
end
