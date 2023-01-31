# frozen_string_literal: true

require 'rails_helper'
include Warden::Test::Helpers

RSpec.describe 'Admin dashboard', integration: true, clean: true, type: :system do
  context 'as a non-admin user' do
    let(:user) { FactoryBot.create(:user) }
    before do
      login_as user
      visit '/dashboard'
    end

    scenario 'does not have settings tab' do
      expect(page).not_to have_link 'Settings'
    end

    scenario 'does not have import csv link' do
      expect(page).not_to have_link 'Import Content From a CSV'
    end

    scenario 'does not have Bulkrax Importers link' do
      expect(page).not_to have_link 'Importers'
    end

    scenario 'does not have Bulkrax Exporters link' do
      expect(page).not_to have_link 'Exporters'
    end
  end

  context 'as an admin user' do
    let(:admin) { FactoryBot.create(:admin) }
    before do
      login_as admin
      # The 2 mocks below are necessary now that we're using Bulkrax' new out-of-box
      #   Ability methods that check whether an admin user can create at least one work
      #   and deposit that work into one AdminSet. It's easier to mock this response
      #   then to alter the user's specific AdminSet abilities.
      allow_any_instance_of(Ability).to receive(:can_export_works?).and_return(true)
      allow_any_instance_of(Ability).to receive(:can_import_works?).and_return(true)
      visit '/dashboard'
    end

    scenario 'view the workflow roles page' do
      click_on 'Workflow Roles'
      expect(page).to have_content 'Assign Role'
    end

    scenario 'does have settings tab' do
      expect(page).to have_link 'Settings'
    end

    scenario 'does  have an import csv link' do
      expect(page).to have_link 'Import Content From a CSV'
    end

    scenario 'does have background jobs tab' do
      expect(page).to have_link 'Background Jobs'
    end

    scenario 'view background jobs page' do
      click_on 'Background Jobs'
      expect(page).to have_content 'Select Job'
    end

    scenario 'does have Bulkrax Importers link' do
      expect(page).to have_link 'Importers'
    end

    scenario 'does have Bulkrax Exporters link' do
      expect(page).to have_link 'Exporters'
    end
    # TODO: Add more admin tests, for eg: stats page, when work is created

    # scenario 'view the statistics page' do
    #   click_on 'Reports'
    #   expect(page).to have_content ''
    # end
  end
end
