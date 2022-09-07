# frozen_string_literal: true
require 'rails_helper'
require(Rails.root.join('spec', 'support', 'new_curate_generic_work_form.rb'))
require(Rails.root.join('spec', 'support', 'wait_for_ajax.rb'))
include Warden::Test::Helpers

RSpec.describe 'Fileset upload', integration: true, admin_set: true, clean: true, js: true, type: :system do
  context 'a logged in user uploads fileset' do
    let(:user_attributes) do
      { uid: 'test@example.com' }
    end
    let(:user) do
      User.new(user_attributes) { |u| u.save(validate: false) }
    end

    let(:new_cgw_form) { NewCurateGenericWorkForm.new }

    before do
      login_as user
      visit("/concern/curate_generic_works/new#files")
    end

    scenario 'without Preservation Master File' do
      click_on 'Upload Fileset'

      expect(find('#message0').text).to eq 'Preservation Master File cannot be empty'
      expect(page).to have_css('li#required-files.incomplete')
    end

    scenario 'with all files and fileset name' do
      new_cgw_form.attach_files
      click_on 'Upload Fileset'

      wait_for_ajax
      expect(find('#message0').text).to eq 'Files uploaded'
      expect(page).to have_css('li#required-files.complete')
      expect(page).to have_css('#upload0:disabled')
      expect(page).to have_css('input#uf0', visible: false, count: 1)

      uf = page.find('input#uf0', visible: false).value
      file_id = Hyrax::UploadedFile.find(uf)

      expect(file_id.file).to eq 'Example fileset'
      expect(file_id.service_file.file.filename).to eq 'sun.png'
      expect(file_id.preservation_master_file.file.filename).to eq 'image.jp2'
      expect(file_id.intermediate_file.file.filename).to eq 'world.png'
      expect(file_id.extracted_text.file.filename).to eq 'image.jp2'
      expect(file_id.transcript.file.filename).to eq 'world.png'
      expect(file_id.fileset_use).to eq 'Primary Content'

      expect(Hyrax::UploadedFile.count).to eq(1)
    end

    scenario 'with multiple filesets' do
      new_cgw_form.attach_files
      click_on 'Upload Fileset'

      wait_for_ajax
      expect(find('#message0').text).to eq 'Files uploaded'
      expect(page).to have_css('li#required-files.complete')
      expect(page).to have_css('#upload0:disabled')
      expect(page).to have_css('input#uf0', visible: false, count: 1)

      click_on '+ Add Fileset'
      within('.fileset-append') do
        fill_in "fsn1", with: "Example 2 fileset"
        attach_file("pmf1", "#{fixture_path}/image.jp2", visible: false)
        find('#fs_use1').find(:xpath, 'option[2]').select_option
      end
      click_on 'Upload Fileset'

      wait_for_ajax
      expect(find('#message1').text).to eq 'Files uploaded'
      expect(page).to have_css('#upload1:disabled')
      expect(page).to have_css('input#uf1', visible: false, count: 1)

      uf = page.find('input#uf0', visible: false).value
      file_id = Hyrax::UploadedFile.find(uf)

      expect(file_id.file).to eq 'Example fileset'
      expect(file_id.service_file.file.filename).to eq 'sun.png'
      expect(file_id.preservation_master_file.file.filename).to eq 'image.jp2'
      expect(file_id.intermediate_file.file.filename).to eq 'world.png'
      expect(file_id.extracted_text.file.filename).to eq 'image.jp2'
      expect(file_id.transcript.file.filename).to eq 'world.png'
      expect(file_id.fileset_use).to eq 'Primary Content'

      uf1 = page.find('input#uf1', visible: false).value
      file_id1 = Hyrax::UploadedFile.find(uf1)

      expect(file_id1.file).to eq 'Example 2 fileset'
      expect(file_id1.preservation_master_file.file.filename).to eq 'image.jp2'
      expect(file_id1.fileset_use).to eq 'Supplemental Content'

      expect(page).to have_selector("input[name='uploaded_files[]'", visible: false, count: 2)

      expect(Hyrax::UploadedFile.count).to eq(2)
    end

    scenario 'without PMF for second filset' do
      new_cgw_form.attach_files
      click_on 'Upload Fileset'

      click_on '+ Add Fileset'
      click_on 'Upload Fileset'

      expect(find('#message1').text).to eq 'Preservation Master File cannot be empty'

      within('.fileset-append') do
        fill_in "fsn1", with: "Example 2 fileset"
        attach_file("pmf1", "#{fixture_path}/image.jp2", visible: false)
      end
      click_on 'Upload Fileset'

      wait_for_ajax
      expect(find('#message1').text).to eq 'Files uploaded'
      expect(page).to have_css('li#required-files.complete')

      expect(page).to have_selector("input[name='uploaded_files[]']", visible: false, count: 2)

      expect(Hyrax::UploadedFile.count).to eq(2)
    end
  end

  context 'when a user is not authenticated' do
    it 'requires the user to sign in' do
      visit("/concern/curate_generic_works/new#files")
      expect(page.current_path).to eq '/users/sign_in'
      expect(page).to have_content 'You need to sign in or sign up before continuing.'
    end
  end
end
