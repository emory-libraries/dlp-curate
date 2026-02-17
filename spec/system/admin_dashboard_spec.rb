# frozen_string_literal: true
require 'rails_helper'
include Warden::Test::Helpers

RSpec.describe 'Admin dashboard', integration: true, clean: true, type: :system do
  let(:user) { FactoryBot.create(:user) }
  before do
    login_as user
    visit '/dashboard'
  end

  context 'as a non-admin user' do
    it('does not have settings tab') { expect(page).not_to have_link 'Settings' }

    it('does not have import csv link') { expect(page).not_to have_link 'Import Content From a CSV' }

    it('does not have Bulkrax Importers link') { expect(page).not_to have_link 'Importers' }

    it('does not have Bulkrax Exporters link') { expect(page).not_to have_link 'Exporters' }
  end

  context 'as an admin user' do
    let(:user) { FactoryBot.create(:admin) }

    it('does have settings tab') { expect(page).to have_link 'Settings' }

    it('does have background jobs tab') { expect(page).to have_link 'Background Jobs' }

    it('does have Bulkrax Importers link') { expect(page).to have_link 'Importers' }

    it('does have Bulkrax Exporters link') { expect(page).to have_link 'Exporters' }

    it 'provides the workflow roles page' do
      click_on 'Workflow Roles'
      expect(page).to have_content 'Assign Role'
    end

    it 'provides the background jobs page' do
      click_on 'Background Jobs'
      expect(page).to have_content 'Select Job'
    end

    it 'does not have an import csv link in Hyrax v5.2.0 (Bulkrax is now the only game)' do
      expect(page).not_to have_link 'Import Content From a CSV'
    end
  end
end
