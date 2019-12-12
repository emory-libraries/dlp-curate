# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Qa::LocalAuthority, type: :model do
  context 'resource_types' do
    it 'has active terms for everything' do
      active_terms = Qa::Authorities::Local.subauthority_for('resource_types').all.select { |term| term[:active] }
      expect(active_terms).not_to be_empty
    end
  end

  context 'administrative_unit' do
    it 'has active terms for everything' do
      active_terms = Qa::Authorities::Local.subauthority_for('administrative_unit').all.select { |term| term[:active] }
      expect(active_terms).not_to be_empty
    end
  end
end
