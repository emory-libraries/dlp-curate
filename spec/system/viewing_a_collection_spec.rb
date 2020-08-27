# frozen_string_literal: true
require 'rails_helper'
include Warden::Test::Helpers

RSpec.describe 'Viewing collections', type: :system, clean: true do
  let(:admin_user) { FactoryBot.create(:admin) }
  let(:admin_collection) { FactoryBot.build(:public_collection_lw, user: admin_user, with_permission_template: true) }
  let(:user) { FactoryBot.create(:user) }
  let(:user_collection) { FactoryBot.build(:public_collection_lw, user: user, with_permission_template: true) }

  before do
    admin_collection.save!
    admin_collection.reload
    user_collection.save!
    user_collection.reload
  end

  context 'when logged in as an admin' do
    before do
      login_as admin_user
    end

    it 'has a delete action on the my collections dashboard' do
      visit "/dashboard/my/collections"
      expect(page).to have_selector(:css, 'a[title="Delete collection"]')
    end

    it 'has a delete action on the all collections dashboard' do
      visit "/dashboard/collections"
      expect(page).to have_selector(:css, 'a[title="Delete collection"]')
    end

    it 'has a delete action on the individual collection dashboard page' do
      visit "/dashboard/collections/#{admin_collection.id}"
      expect(page).to have_selector(:css, 'a[title="Delete this collection"]')
      visit "/dashboard/collections/#{user_collection.id}"
      expect(page).to have_selector(:css, 'a[title="Delete this collection"]')
    end

    it 'has delete selected button' do
      visit "dashboard/collections"
      find("input[type='checkbox'][id='check_all']").set(true)
      expect(page).to have_selector("button[id='delete-collections-button']")
    end
  end

  context 'when logged in as a non-admin user' do
    before do
      login_as user
    end

    it 'does not have a delete action on the my collections dashboard' do
      visit "/dashboard/my/collections"
      expect(page).to have_selector(:css, 'a[title="Edit collection"]')
      expect(page).not_to have_selector(:css, 'a[title="Delete collection"]')
    end

    it 'does not have a delete action on the all collections dashboard' do
      visit "/dashboard/collections"
      expect(page).not_to have_selector(:css, 'a[title="Delete collection"]')
    end

    it 'does not have a delete action on the individual collection dashboard page' do
      visit "/dashboard/collections/#{user_collection.id}"
      expect(page).to have_selector(:css, 'a[title="Edit this collection"]')
      expect(page).not_to have_selector(:css, 'a[title="Delete this collection"]')
    end

    it 'does not have delete selected button' do
      visit "dashboard/collections"
      find("input[type='checkbox'][id='check_all']").set(true)
      expect(page).not_to have_selector("button[id='delete-collections-button']")
    end

    it 'does not have add to collection button on a collection show page' do
      visit "dashboard/collections/#{user_collection.id}"
      expect(page).not_to have_selector("button[id='add-to-collection-button']")
    end

    it 'does not have add a subcollection button on a collection show page' do
      visit "dashboard/collections/#{user_collection.id}"
      expect(page).not_to have_selector("button[id='add-subcollection-button']")
    end

    it 'does not have create new collection as subcollection link on a collection show page' do
      visit "dashboard/collections/#{user_collection.id}"
      expect(page).not_to have_selector("a[id='create-new-collection-sub-link']")
    end

    context 'Items table heading' do
      it 'shows "Deposited Items", not "Items"' do
        visit "dashboard/collections"
        ths = find_all('table#collections-list-table thead tr th').map(&:text)

        expect(ths.include?('Deposited Items')).to be_truthy
        expect(ths.include?('Items')).to be_falsey
      end
    end

    context 'deposit/source element' do
      before do
        user_collection.source_collection_id = admin_collection.id
        user_collection.save!
        user_collection.reload
      end

      describe 'viewing deposit collection' do
        it 'does have the Source Collection element on public page' do
          visit "/collections/#{user_collection.id}"

          expect(page).to have_content "Source Collection"
          expect(page).to have_link(admin_collection.title[0], href: "/collections/#{admin_collection.id}")
        end

        it 'does have the Source Collection element on dashboard page' do
          visit "/dashboard/collections/#{user_collection.id}"

          expect(page).to have_content "Source Collection"
          expect(page).to have_link(admin_collection.title[0], href: "/dashboard/collections/#{admin_collection.id}")
        end
      end

      describe 'viewing source collection' do
        it 'does not have the Source Collection element on public page' do
          visit "/collections/#{admin_collection.id}"

          expect(page).not_to have_content "Source Collection"
        end

        it 'does not have the Source Collection element on dashboard page' do
          visit "/dashboard/collections/#{admin_collection.id}"

          expect(page).not_to have_content "Source Collection"
        end
      end
    end
  end
end
