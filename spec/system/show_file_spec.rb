# frozen_string_literal: true

require 'rails_helper'
include Warden::Test::Helpers

RSpec.describe "Showing a file:", integration: true, clean: true, type: :system do
  include PreservationEvents

  let(:user) { FactoryBot.create(:user) }
  let(:file_title) { 'Some kind of title' }
  let(:work) { FactoryBot.build(:work, user: user) }
  let(:file_set) { FactoryBot.create(:file_set, user: user, title: [file_title], pcdm_use: 'Primary Content') }
  let(:file) { File.open(fixture_path + '/world.png') }
  let(:file1) { File.open(fixture_path + '/sun.png') }
  let(:file2) { File.open(fixture_path + '/image.jp2') }
  let(:file3) { File.open(fixture_path + '/book_page/0003_extracted_text.pos') }
  let(:pe) do
    {
      'type' => 'Characterization',
      'start' => 5.minutes.from_now,
      'outcome' => 'Success',
      'details' => 'Example details',
      'software_version' => 'Curate v.1',
      'user' => 'userexample'
    }
  end

  before do
    login_as user
    Hydra::Works::AddFileToFileSet.call(file_set, file, :preservation_master_file)
    Hydra::Works::AddFileToFileSet.call(file_set, file1, :service_file)
    Hydra::Works::AddFileToFileSet.call(file_set, file2, :intermediate_file)
    Hydra::Works::AddFileToFileSet.call(file_set, file3, :extracted)
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
    before do
      visit hyrax_file_set_path(file_set)
    end

    it 'shows additional files' do
      expect(page).to have_content('world.png')
      expect(page).to have_content('Preservation Master File')
      expect(page).to have_content('sun.png')
      expect(page).to have_content('Service File')
      expect(page).to have_content('image.jp2')
      expect(page).to have_content('Intermediate File')
    end

    it 'shows fileset id' do
      expect(find('#fileset-id').text).to include("FileSet ID: #{file_set.id}")
    end

    it 'shows fileset category' do
      expect(find('#fileset-category').text).to include('Primary Content')
    end

    it 'shows a file details block' do
      expect(page).to have_content('Preservation Master File Details')
      expect(page).to have_content('Depositor')
      expect(page).to have_content('Date Uploaded')
      expect(page).to have_content('Date Modified')
      expect(page).to have_content('Fixity Check')
      expect(page).to have_content('Characterization')
    end

    it 'shows an activity block' do
      expect(first('.activity-header').text).to eq('Activity')
      expect(page).to have_css('table#activity')
    end

    it 'shows pmf download link' do
      expect(first('#file_download').text).to eq('Download Preservation Master File')
    end

    it 'does not show Single-Use Links section' do
      expect(page).not_to have_content('Single-Use Links')
      expect(page).not_to have_css('table.table.table-striped.table-condensed.file_set.single-use-links')
      expect(page).not_to have_link('Create Single-Use Link')
    end

    context 'within the preservation events block' do
      it 'shows the right header' do
        expect(page).to have_content('Preservation Events')
      end

      context 'when there are events' do
        it 'shows a table with the right headers' do
          table_headers = all('#fs-preservation-event-table th').map(&:text)

          expect(table_headers).to eq(["Event", "Timestamp", "Outcome", "Detail", "User", "Software"])
        end

        it 'shows a table with the right values' do
          table_values = all('#fs-preservation-event-table td').map(&:text)
          preservation_event = file_set.preservation_event.first

          expect(table_values).to eq(
            [
              preservation_event.event_type.first,
              "Start: #{preservation_event.event_start.first} End: #{preservation_event.event_end.first}",
              preservation_event.outcome.first,
              preservation_event.event_details.first,
              preservation_event.initiating_user.first,
              preservation_event.software_version.first
            ]
          )
        end

        it 'displays preservation events in reverse chronological order' do
          create_preservation_event(file_set, pe)
          visit hyrax_file_set_path(file_set)
          table_values = all('#fs-preservation-event-table td').map(&:text)
          # Characterization event is hard-coded to start five minutes after Virus Check
          expect(table_values.index("Characterization")).to be < table_values.index("Virus Check")
        end
      end
    end
  end

  context 'when fixity check passes' do
    before do
      visit hyrax_file_set_path(file_set)
      click_on 'Run Fixity check'
    end

    it 'shows result of fixity check' do
      expect(page).to have_content 'passed 4 Files with 4 total versions checked'
    end
  end

  context 'when fixity check fails' do
    before do
      ChecksumAuditLog.create!(passed: true, file_set_id: file_set.id, file_id: file_set.preservation_master_file.id)
      ChecksumAuditLog.create!(passed: true, file_set_id: file_set.id, file_id: file_set.intermediate_file.id)
      ChecksumAuditLog.create!(passed: false, file_set_id: file_set.id, file_id: file_set.service_file.id)
      visit hyrax_file_set_path(file_set)
    end

    it 'shows result of fixity check' do
      expect(page).to have_content 'FAIL 3 Files with 3 total versions checked'
    end
  end

  context 'when downloading files' do
    it 'downloads extracted text file correctly' do
      visit hyrax_file_set_path(file_set)
      expect(page).to have_http_status(:ok)
      click_on '0003_extracted_text.pos'
      expect(page).to have_http_status(:success)
    end
  end

  context 'social media share options are not present' do
    it 'doesnt show share buttons' do
      visit hyrax_file_set_path(file_set)
      expect(page).not_to have_link(title: "Facebook", exact: true)
      expect(page).not_to have_link(title: "Twitter", exact: true)
      expect(page).not_to have_link(title: "Google+", exact: true)
      expect(page).not_to have_link(title: "Tumblr", exact: true)
    end
  end

  context 'Re-characterize FileSet' do
    it 'has a link to re-characterize the fileset' do
      visit hyrax_file_set_path(file_set)
      form = page.find("form[action='/concern/file_sets/#{file_set.id}/re_characterize']")

      within form do
        page.find("input[value='Re-characterize FileSet']")
      end
    end
  end
end
