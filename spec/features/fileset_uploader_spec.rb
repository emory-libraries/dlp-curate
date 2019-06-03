# frozen_string_literal: true
require 'rails_helper'
include Warden::Test::Helpers

RSpec.feature 'Fileset upload' do
  context 'a logged in user uploads fileset', js: true do
    let(:user_attributes) do
      { uid: 'test@example.com' }
    end
    let(:user) do
      User.new(user_attributes) { |u| u.save(validate: false) }
    end

    before do
      login_as user
      visit("/concern/curate_generic_works/new#files")
    end

    scenario 'without Preservation Master File' do
      click_on 'Upload'

      expect(find("#message").text).to eq 'Preservation Master File cannot be empty'
      expect(page).to have_css('li#required-files.incomplete')
    end

    scenario 'with all files and fileset name' do
      fill_in "fsn", with: "Example fileset"
      attach_file("pmf", "#{fixture_path}/image.jp2", visible: false)
      attach_file("sf", "#{fixture_path}/sun.png", visible: false)
      attach_file("imf", "#{fixture_path}/world.png", visible: false)
      attach_file("et", "#{fixture_path}/image.jp2", visible: false)
      attach_file("ts", "#{fixture_path}/world.png", visible: false)
      click_on 'Upload'

      expect(find("#message").text).to eq 'Files uploaded'
      expect(page).to have_css('li#required-files.complete')

      uf = first('input#uf', visible: false).value
      file_id = Hyrax::UploadedFile.find(uf)

      expect(file_id.file).to eq 'Example fileset'
      expect(file_id.service_file.file.filename).to eq 'sun.png'
      expect(file_id.preservation_master_file.file.filename).to eq 'image.jp2'
      expect(file_id.intermediate_file.file.filename).to eq 'world.png'
      expect(file_id.extracted_text.file.filename).to eq 'image.jp2'
      expect(file_id.transcript.file.filename).to eq 'world.png'
    end
  end
end
