# frozen_string_literal: true
require 'rails_helper'
include Warden::Test::Helpers

RSpec.describe 'Bulkrax CSV importer', clean: true, js: true, type: :system do
  context 'not logged in' do
    it 'redirects you to login when visiting dashboard ' do
      visit '/dashboard'
      expect(page).to have_current_path('/users/sign_in')
    end

    it 'redirects you to login when attempting to create new importer ' do
      visit '/importers/new'
      expect(page).to have_current_path('/users/sign_in')
    end
  end

  context 'logged in user' do
    let(:user_attributes) { { uid: 'test@example.com' } }
    let(:user) { User.new(user_attributes) { |u| u.save(validate: false) } }
    let(:csv_file) { File.join(fixture_path, 'csv_import', 'good', 'Bulkrax_Test_CSV.csv') }

    before { login_as user }

    it 'displays importers on Dashboard' do
      visit '/dashboard'

      expect(page).to have_css('li a span.sidebar-action-text', text: 'Importers')
    end

    context 'within importers/new' do
      before do
        visit '/importers/new'
        select('CSV - Comma Separated Values', from: 'Parser')
      end

      it 'has the expected CSV importer fields' do
        expect(find_all('#importer_parser_fields_visibility option').map(&:text)).to match_array(
          ["Emory High Download", "Emory Low Download", "Private", "Public", "Public Low View",
           "Rose High View"]
        )
      end

      it 'accepts a CSV to upload' do
        page.choose('Upload a File')
        attach_file('importer[parser_fields][file]', csv_file, make_visible: true)
        click_on('Create and Validate')
      end
    end
  end
end
