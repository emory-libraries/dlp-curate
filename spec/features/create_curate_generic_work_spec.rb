# Generated via
#  `rails generate hyrax:work CurateGenericWork`
require 'rails_helper'
include Warden::Test::Helpers

# NOTE: If you generated more than one work, you have to set "js: true"
RSpec.feature 'Create a CurateGenericWork' do
  context 'a logged in user' do
    let(:user_attributes) do
      { uid: 'test@example.com' }
    end
    let(:user) do
      User.new(user_attributes) { |u| u.save(validate: false) }
    end
    let(:admin_set_id) { AdminSet.find_or_create_default_admin_set_id }
    let(:permission_template) { Hyrax::PermissionTemplate.find_or_create_by!(source_id: admin_set_id) }
    let(:workflow) { Sipity::Workflow.create!(active: true, name: 'test-workflow', permission_template: permission_template) }

    before do
      # Create a single action that can be taken
      Sipity::WorkflowAction.create!(name: 'submit', workflow: workflow)

      # Grant the user access to deposit into the admin set.
      Hyrax::PermissionTemplateAccess.create!(
        permission_template_id: permission_template.id,
        agent_type: 'user',
        agent_id: user.user_key,
        access: 'deposit'
      )
      login_as user
    end

    scenario "'descriptions' loads with all its inputs", js: true do
      visit '/concern/curate_generic_works/new'

      expect(page).to have_css('#metadata input#curate_generic_work_title')
      expect(page).to have_css('#metadata select#curate_generic_work_rights_statement')

      click_link('Additional descriptive fields')
      expect(page).to have_content('Add another Content genre')

      click_link('Additional admin fields', wait: 10)
      expect(page).to have_css('#metadata input#curate_generic_work_staff_note')
      expect(page).to have_content('Add another Staff note')
    end

    scenario "metadata fields are validated", js: true do
      visit('/concern/curate_generic_works/new')

      fill_in "curate_generic_work[title][]", with: "Example title"
      fill_in "curate_generic_work[holding_repository]", with: "Woodruff"
      fill_in "curate_generic_work[content_type]", with: "Book"
      select("In Copyright", from: "Rights statement")
      fill_in "curate_generic_work[rights_statement_controlled]", with: "Controlled Rights Statement"
      fill_in "curate_generic_work[data_classification][]", with: "Excel spreadsheet"
      fill_in "curate_generic_work[primary_repository_ID]", with: "123ABC"
      find('body').click

      expect(page).to have_css('li#required-metadata.complete')
    end

    scenario "Create Curate Work" do
      visit '/concern/curate_generic_works/new'

      # If you generate more than one work uncomment these lines
      # choose "payload_concern", option: "CurateGenericWork"
      # click_button "Create work"

      expect(page).to have_content "Add New Curate Generic Work"
      click_link "Files" # switch tab
      expect(page).to have_content "Add files"
      expect(page).to have_content "Add folder"
      within('span#addfiles') do
        attach_file("files[]", "#{Hyrax::Engine.root}/spec/fixtures/image.jp2", visible: false)
        attach_file("files[]", "#{Hyrax::Engine.root}/spec/fixtures/jp2_fits.xml", visible: false)
      end
      click_link "Descriptions" # switch tab
      # fill_in('Title', with: 'My Test Work')
      # fill_in('Creator', with: 'Doe, Jane')
      # fill_in('Keyword', with: 'testing')
      # select('In Copyright', from: 'Rights statement')

      # With selenium and the chrome driver, focus remains on the
      # select box. Click outside the box so the next line can't find
      # its element
      find('body').click
      choose('curate_generic_work_visibility_open')
      expect(page).to have_content('Please note, making something visible to the world (i.e. marking this as Public) may be viewed as publishing which could impact your ability to')
      check('agreement')

      # click_on('Save')
      # expect(page).to have_content('My Test Work')
      # expect(page).to have_content "Your files are being processed by Hyrax in the background."
    end
  end
end
