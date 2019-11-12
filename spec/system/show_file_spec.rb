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
    let(:work2)             { FactoryBot.build(:work, user: user) }
    let(:file_set2)         { FactoryBot.create(:file_set, user: user, title: ['Some title'], pcdm_use: 'Primary Content') }
    let(:filename2)         { 'sample-file.pdf' }
    let(:path_on_disk)      { File.join(fixture_path, filename2) }
    let(:file4)             { File.open(path_on_disk) }

    before do
      login_as user
      Hydra::Works::AddFileToFileSet.call(file_set2, file4, :preservation_master_file)
      work2.ordered_members << file_set2
      work2.save!
      CharacterizeJob.perform_now(file_set2, file_set2.id, path_on_disk)
    end

    it 'displays technical metadata' do
      visit hyrax_file_set_path(file_set2)
      expect(page).to have_content('File Title:')
      expect(page).to have_content('File Path:')
      expect(page).to have_content('File Size:')
      expect(page).to have_content('Mime Type:')
      expect(page).to have_content('Created:')
      expect(page).to have_content('Valid:')
      expect(page).to have_content('Well Formed:')
      expect(page).to have_content('Creating Application Name:')
      expect(page).to have_content('Puid:')
      expect(page).to have_content('Page Count:')
      expect(page).to have_content('File Format:')
    end
  end
end
