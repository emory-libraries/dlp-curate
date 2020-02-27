# frozen_string_literal: true
require 'rails_helper'
include Warden::Test::Helpers

RSpec.describe 'viewing a collection', :clean, type: :system, js: true do
  let(:admin_user) { FactoryBot.build(:admin) }
  let(:collections_csv) { File.join(fixture_path, 'csv_import', 'collections', 'collections.csv') }
  let(:collection) do
    CurateCollectionImporter.new.import(collections_csv, "/dev/null")
    Collection.where(local_call_number: "MSS1218").first
  end
  let(:multi_fields) do
    [
      :holding_repository,
      :administrative_unit,
      :contributors,
      :keywords,
      :subject_topics,
      :subject_names,
      :subject_geo,
      :subject_time_periods,
      :notes,
      :rights_documentation,
      :staff_notes,
      :emory_ark
    ]
  end
  let(:singular_fields) do
    [
      :abstract,
      :primary_language,
      :finding_aid_link,
      :institution,
      :local_call_number,
      :sensitive_material,
      :internal_rights_note,
      :system_of_record_ID,
      :primary_repository_ID
    ]
  end
  let(:private_work) { FactoryBot.build(:private_work) }
  before do
    private_work.member_of_collections = [collection]
    private_work.save!
    ENV['LUX_BASE_URL'] = 'empl.com'
  end

  it 'has all the expected metadata fields' do
    visit "/collections/#{collection.id}"
    expect(page).to have_content("empl.com/purl/#{collection.id}")
    expect(page).to have_content 'Robert Langmuir African American Photograph Collection'
    expect(page).to have_content 'Created by: Langmuir, Robert, collector'
    expect(page).to have_content 'Rose Library'
    singular_fields.each do |fieldname|
      expect(page).to have_content collection.send(fieldname)
    end
    multi_fields.each do |fieldname|
      expect(page).to have_content collection.send(fieldname).first
    end
    expect(page).to have_content '0 Items'
    expect(page).not_to have_content 'Works (1)'
    expect(page).not_to have_content 'Test title'
  end

  it 'has access to private works in a public collection when signed in as admin' do
    login_as admin_user
    visit "/collections/#{collection.id}"
    expect(page).to have_content 'Works (1)'
    expect(page).to have_content 'Test title'
    expect(page).to have_content 'Private'
  end
end
