require 'rails_helper'
include Warden::Test::Helpers

RSpec.describe "Showing a file:", integration: true, clean: true, type: :system do
  let(:user) { FactoryBot.create(:user) }
  let(:file_title) { 'Some kind of title' }
  let(:work) { FactoryBot.build(:work, user: user) }
  let(:file_set) { FactoryBot.create(:file_set, user: user, title: [file_title]) }
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
  end
end
