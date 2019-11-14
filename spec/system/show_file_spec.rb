require 'rails_helper'
include Warden::Test::Helpers

RSpec.describe "Showing a file:", integration: true, clean: true, type: :system do
  let(:user) { FactoryBot.create(:user) }
  let(:file_title) { 'Some kind of title' }
  let(:work) { FactoryBot.build(:work, user: user) }
  let(:file_set) { FactoryBot.create(:file_set, user: user, title: [file_title], pcdm_use: 'Primary Content') }
  let(:file) { File.open(fixture_path + '/world.png') }
  let(:file1) { File.open(fixture_path + '/sun.png') }
  let(:file2) { File.open(fixture_path + '/image.jp2') }

  before do
    login_as user
    Hydra::Works::AddFileToFileSet.call(file_set, file, :original_file)
    Hydra::Works::AddFileToFileSet.call(file_set, file1, :service_file)
    Hydra::Works::AddFileToFileSet.call(file_set, file2, :intermediate_file)
    work.ordered_members << file_set
    work.save!
  end

  context 'when the user tries to click on parent work from a show page' do
    it 'shows the edit page again' do
      visit hyrax_file_set_path(file_set)
      expect(page).to have_content('Parent Work')
      click_link 'Parent Work'
      expect(page).to have_content('Some kind of title')
    end
  end

  context 'on a fileset view page' do
    it 'shows additional files' do
      visit hyrax_file_set_path(file_set)
      expect(page).to have_content('sun.png')
      expect(page).to have_content('Service File')
      expect(page).to have_content('image.jp2')
      expect(page).to have_content('Intermediate File')
    end

    it 'shows fileset category' do
      visit hyrax_file_set_path(file_set)
      expect(find('#fileset-category').text).to include('Primary Content')
    end
  end

  context 'when characterization is run' do
    let(:characterization)  { class_double("Hydra::FileCharacterization").as_stubbed_const }
    let(:work2)             { FactoryBot.build(:work, user: user) }
    let(:file_set2)         { FactoryBot.create(:file_set, user: user, title: ['Some title'], pcdm_use: 'Primary Content') }
    let(:filename2)         { 'sample-file.pdf' }
    let(:path_on_disk)      { File.join(fixture_path, filename2) }
    let(:file4)             { File.open(path_on_disk) }
    let(:fits_filename)     { 'fits_1.4.0_sample_pdf.xml' }
    let(:fits_response)     { IO.read(File.join(fixture_path, fits_filename)) }
    let(:digest)            { class_double("Digest::SHA256") }
    let(:hexdigest_value)   { "urn:sha256:9f08fe67e102fc94950070cf5de88ba760846516daf2c76a1167c809ec37b37a" }

    before do
      login_as user
      Hydra::Works::AddFileToFileSet.call(file_set2, file4, :preservation_master_file)
      work2.ordered_members << file_set2
      work2.save!
      allow(characterization).to receive(:characterize).and_return(fits_response)
      allow(digest).to receive_message_chain(:file, :hexdigest, :prepend).and_return(hexdigest_value)
      Hydra::Works::CharacterizationService.run(file_set2.preservation_master_file, path_on_disk)
      file_set2.preservation_master_file.save!
      file_set2.update_index
    end

    it 'displays required technical metadata' do
      visit hyrax_file_set_path(file_set2)
      expect(page).to have_content('Original Checksum:')
      expect(page).to have_content('urn:sha256:9f08fe67e102fc94950070cf5de88ba760846516daf2c76a1167c809ec37b37a')
      expect(page).to have_content('File Path: /Users/wulman/Desktop/sample-file.pdf')
      expect(page).to have_content('File Size: 7618')
      expect(page).to have_content('Mime Type: application/pdf')
      expect(page).to have_content('Created: 2015:05:14 19:47:31Z')
      expect(page).to have_content('Valid: true')
      expect(page).to have_content('Well Formed: true')
      expect(page).to have_content('Creating Application Name: Mac OS X 10.10.3 Quartz PDFContext/TextEdit')
      expect(page).to have_content('Puid: fmt/17')
      expect(page).to have_content('Page Count: 1')
      expect(page).to have_content('File Format: pdf (Portable Document Format)')
    end
  end
end
