# frozen_string_literal: true
require 'rails_helper'
include Warden::Test::Helpers

RSpec.describe 'viewing a collection', :clean, type: :system, js: true do
  let(:admin_user) { FactoryBot.build(:admin) }
  let(:langmuir_csv) { File.join(fixture_path, 'csv_import', 'collections', 'langmuir_collection.csv') }
  let(:collection) do
    CurateCollectionImporter.new.import(langmuir_csv)
    Collection.last
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
      :note,
      :rights_documentation,
      :staff_note,
      :legacy_ark
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

  it 'has all the expected metadata fields' do
    visit "/collections/#{collection.id}"
    expect(page).to have_content 'Robert Langmuir African American Photograph Collection'
    expect(page).to have_content 'Created by: Langmuir, Robert, collector'
    expect(page).to have_content 'Rose Library'
    singular_fields.each do |fieldname|
      expect(page).to have_content collection.send(fieldname)
    end
    multi_fields.each do |fieldname|
      expect(page).to have_content collection.send(fieldname).first
    end
  end
end
