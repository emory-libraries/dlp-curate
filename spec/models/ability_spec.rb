# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ability do
  let(:user) { FactoryBot.create(:user) }
  let(:admin) { FactoryBot.create(:admin) }

  describe 'Manage Zizia::CsvImport' do
    context 'when user is an admin' do
      it 'returns true' do
        expect(admin.can?(:manage, Zizia::CsvImport)).to eq(true)
      end
    end

    context 'when user is not an admin' do
      it 'returns false' do
        expect(user.can?(:manage, Zizia::CsvImport)).to eq(false)
      end
    end
  end

  describe 'Manage Zizia::CsvImportDetail' do
    context 'when user is an admin' do
      it 'returns true' do
        expect(admin.can?(:manage, Zizia::CsvImportDetail)).to eq(true)
      end
    end

    context 'when user is not an admin' do
      it 'returns false' do
        expect(user.can?(:manage, Zizia::CsvImportDetail)).to eq(false)
      end
    end
  end
end
