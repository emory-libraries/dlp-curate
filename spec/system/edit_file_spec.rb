require 'rails_helper'
include Warden::Test::Helpers

RSpec.describe "Showing a file:", integration: true, clean: true, type: :system do
  let(:user) { FactoryBot.create(:user) }
  let(:file_title) { 'Some kind of title' }
  let(:work) { FactoryBot.build(:work, user: user) }
  let(:file_set) { FactoryBot.create(:file_set, user: user, title: [file_title]) }
  let(:file) { File.open(fixture_path + '/sun.png') }

  before do
    login_as user
    Hydra::Works::AddFileToFileSet.call(file_set, file, :original_file)
    work.ordered_members << file_set
    work.save!
  end

  context 'when the user tries to update file label' do
    it 'shows the edit page again' do
      visit edit_hyrax_file_set_path(file_set)
      click_link 'Descriptions'
      fill_in('Title', with: 'My Test Work')
      find('input[name="commit"]').click
    end
  end
end
