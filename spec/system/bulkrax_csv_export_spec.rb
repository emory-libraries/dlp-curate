# frozen_string_literal: true
require 'rails_helper'
include Warden::Test::Helpers

RSpec.describe 'Bulkrax CSV exporter', clean: true, js: true, type: :system do
  context 'not logged in' do
    it 'redirects you to login when visiting dashboard ' do
      visit '/dashboard'
      expect(page.current_path).to include('/sign_in')
    end

    it 'redirects you to login when attempting to create new exporter ' do
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
      allow_any_instance_of(Ability).to receive(:can_export_works?).and_return(true)
    end

    it 'displays exporters on Dashboard' do
      visit '/dashboard'

      expect(page).to have_css('li a span.sidebar-action-text', text: 'Exporters')
    end

    context 'Object IDs export' do
      before do
        visit '/exporters/new'
      end

      it 'contains the right elements for Object IDs' do
        expect(page).to have_css("option[value='object_ids']", text: 'Object IDs')
        select 'Object IDs', from: 'exporter_export_from'
        expect(page).to have_css('div.form-group.text.exporter_export_source_object_ids.required label', text: 'Object IDs')
      end

      context 'creating a new export' do
        before do
          fill_in 'Name required', with: 'ID Test'
          select 'Metadata Only', from: 'exporter_export_type'
          select 'Object IDs', from: 'exporter_export_from'
          fill_in 'Object IDs', with: "#{collection.id}|#{work.id}"
          select 'CSV - Comma Separated Values', from: 'exporter_parser_klass'
          find("input[value='Create and Export']").click
        end

        it 'redirects to index with a Test link present' do
          expect(page).to have_link('ID Test', href: '/exporters/1?locale=en')
        end

        context 'on exporter show page' do
          it 'has Title as a column on all entry lists' do
            click_link 'ID Test'

            expect(page).to have_selector('th', text: 'Title', count: 3, visible: false)
          end
        end
      end
    end
  end
end
