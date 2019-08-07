# frozen_string_literal: true

require 'rails_helper'
include Warden::Test::Helpers

RSpec.describe 'Edit an existing collection', :clean, type: :system, js: true do
  let(:collection) { Collection.create!(collection_attrs) }
  let(:collection) { FactoryBot.create(:collection_lw, user: admin) }
  let(:admin) { FactoryBot.create :admin }

  let(:collection_attrs) do
    {
      title: ['Robert Langmuir African American Photograph Collection'],
      institution: 'Emory University',
      creator: ['Langmuir, Robert, collector.'],
      holding_repository: ['Stuart A. Rose Manuscript, Archives, and Rare Book Library'],
      administrative_unit: ['Stuart A. Rose Manuscript, Archives, and Rare Book Library'],
      contact_information: 'Woodruff Library',
      abstract: 'Collection of photographs depicting African American life and culture collected by Robert Langmuir.',
      primary_language: 'English',
      local_call_number: 'MSS1218',
      keywords: ['keyword1', 'keyword2']
    }
  end

  before do
    # Set all the attributes of collection
    # Normally we'd do this in the FactoryBot factory, but in this case we want
    # to use the Hyrax factories.
    collection_attrs.each do |k, v|
      collection.send((k.to_s + "=").to_sym, v)
    end
    collection.save
  end

  context 'logged in as an admin user' do
    before { login_as admin }

    scenario 'successfully edits the work' do
      visit "/dashboard/collections/#{collection.id}/edit"
      expect(find_field('Title').value).to eq 'Robert Langmuir African American Photograph Collection'
      expect(find_field('Library').value).to eq 'Stuart A. Rose Manuscript, Archives, and Rare Book Library'
      expect(find_field('Creator').value).to eq 'Langmuir, Robert, collector.'
      expect(find_field('Description/Abstract').value).to eq 'Collection of photographs depicting African American life and culture collected by Robert Langmuir.'
      click_on 'Additional fields'
      expect(find_field('Administrative Unit').value).to eq 'Stuart A. Rose Manuscript, Archives, and Rare Book Library'

      # Edit some fields in the form
      fill_in 'Title', with: 'New Title'

      click_on 'Save changes'

      # Now the form should have the new values
      expect(page).to have_content 'New Title'
    end
  end
end
