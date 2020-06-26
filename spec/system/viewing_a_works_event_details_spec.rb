# frozen_string_literal: true
require 'rails_helper'
include Warden::Test::Helpers

RSpec.describe 'viewing a the event details page for a work', type: :system, clean: true do
  let(:admin_user) { FactoryBot.create(:admin) }
  let(:work) { FactoryBot.build(:work_with_full_metadata, user: admin_user) }
  before do
    login_as admin_user
    work.save!
    work.reload
    visit "/concern/curate_generic_works/#{work.id}/event_details?locale=en"
  end

  it "loads the page with a main title" do
    expect(body).to have_content('View Preservation Details')
  end
end
