# frozen_string_literal: true

require 'rails_helper'
include Warden::Test::Helpers

RSpec.describe 'Edit an existing collection', :clean, type: :system, js: true do
  let(:collection) { FactoryBot.create(:collection_lw, user: admin) }
  let(:user) { FactoryBot.create(:user) }
  let(:work1) { FactoryBot.build(:work, user: admin) }
  let(:file_set) { FactoryBot.create(:file_set, user: admin, title: ["Test title"], pcdm_use: "Primary Content") }
  let(:file) { File.open(fixture_path + '/sun.png') }
  let(:admin) { FactoryBot.create :admin }

  let(:collection_attrs) do
    {
      title:               ['Robert Langmuir African American Photograph Collection'],
      institution:         'Emory University',
      creator:             ['Langmuir, Robert, collector.'],
      holding_repository:  ['Stuart A. Rose Manuscript, Archives, and Rare Book Library'],
      administrative_unit: ['Stuart A. Rose Manuscript, Archives, and Rare Book Library'],
      contact_information: 'Woodruff Library',
      abstract:            'Collection of photographs depicting African American life and culture collected by Robert Langmuir.',
      primary_language:    'English',
      local_call_number:   'MSS1218',
      keywords:            ['keyword1', 'keyword2']
    }
  end

  before do
    # Set all the attributes of collection
    # Normally we'd do this in the FactoryBot factory, but in this case we want
    # to use the Hyrax factories.
    collection_attrs.each do |k, v|
      collection.send((k.to_s + "=").to_sym, v)
    end
    Hydra::Works::AddFileToFileSet.call(file_set, file, :original_file)
    work1.ordered_members << file_set
    work1.member_of_collections << collection
    work1.save!
  end

  context 'logged in as an admin user' do
    before { login_as admin }

    scenario 'successfully edits the collection' do
      visit "/dashboard/collections/#{collection.id}/edit"
      expect(find_field('Title (title)').value).to eq 'Robert Langmuir African American Photograph Collection'
      expect(find_field('Library (holding_repository)').value).to eq 'Stuart A. Rose Manuscript, Archives, and Rare Book Library'
      expect(find_field('Creator (creator)').value).to eq 'Langmuir, Robert, collector.'
      expect(find_field('Description/Abstract (abstract)').value).to eq 'Collection of photographs depicting African American life and culture collected by Robert Langmuir.'
      click_on 'Additional fields'
      expect(find_field('Administrative Unit (administrative_unit)').value).to eq 'Stuart A. Rose Manuscript, Archives, and Rare Book Library'
      expect(page).to have_content 'Thumbnail'
      first('#s2id_collection_thumbnail_id', minimum: 1).click
      find('li.select2-result').click
      first('body').click
      # Edit some fields in the form
      fill_in 'Title (title)', with: 'New Title'
      click_on 'Save changes'
      # Now the form should have the new values
      expect(page).to have_content 'New Title'
      expect(page).to have_content file_set.id
    end

    scenario 'successfully uploads a banner image' do
      visit "/dashboard/collections/#{collection.id}/edit"
      expect(page).to have_link('Branding', href: '#branding')
      click_on 'Branding'
      attach_file("collection_banner", (fixture_path + '/balloon.jpeg'), visible: false)
      expect(find("input[name='banner_files[]']", visible: false).value).to eq '1'
      click_on 'Save changes'
      expect(page).to have_content 'balloon.jpeg'
    end
  end
end
