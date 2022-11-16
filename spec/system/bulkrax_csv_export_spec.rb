# frozen_string_literal: true
require 'rails_helper'
include Warden::Test::Helpers

RSpec.describe 'Bulkrax CSV exporter', clean: true, js: true, type: :system do
  context 'not logged in' do
    it 'redirects you to login when visiting dashboard ' do
      visit '/dashboard'
      expect(page.current_path).to include('/sign_in')
    end

    it 'redirects you to login when attempting to create new importer ' do
      visit '/exporters/new'
      expect(page.current_path).to include('/sign_in')
    end
  end

  context 'logged in admin user' do
    let(:admin) { FactoryBot.create(:admin) }
    let(:collection) { FactoryBot.create(:collection_lw, user: admin) }
    let(:work) { FactoryBot.build(:work, user: admin) }
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
      collection_attrs.each do |k, v|
        collection.send((k.to_s + "=").to_sym, v)
      end
      Hydra::Works::AddFileToFileSet.call(file_set, file, :original_file)
      work.ordered_members << file_set
      work.member_of_collections << collection
      work.save!
      login_as admin
    end

    it 'displays importers on Dashboard' do
      visit '/dashboard'

      expect(page).to have_css('li a span.sidebar-action-text', text: 'Exporters')
    end

    context 'within importers/new' do
      before do
        visit '/exporters/new'
        fill_in 'Name required', with: 'Test'
        select 'Metadata Only', from: 'exporter_export_type'
        select 'Collection', from: 'exporter_export_from'
        select 'CSV - Comma Separated Values', from: 'exporter_parser_klass'
        find("input[value='Create and Export']").click
      end

      it 'redirects to index with a Test link present' do
        expect(page).to have_link('Test', href: '/exporters/1?locale=en')
      end
    end
  end
end
