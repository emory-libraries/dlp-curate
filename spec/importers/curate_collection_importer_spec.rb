# frozen_string_literal: true
require 'rails_helper'

# Deprecation Warning: As of Curate v3, Zizia will be removed. This is an artifact
#   of the Zizia install that will likely be removed.
RSpec.describe CurateCollectionImporter, :clean do
  subject(:cci) { described_class.new }
  let(:collections_csv) { File.join(fixture_path, 'csv_import', 'collections', 'collections.csv') }
  let(:langmuir_collection) do
    cci.import(collections_csv, "/dev/null")
    Collection.where(local_call_number: "MSS1218").first
  end
  let(:yellowbacks_collection) do
    Collection.where(local_call_number: "YELLOWBACKS").first
  end

  it 'makes collection objects' do
    cci.import(collections_csv, "/dev/null")
    expect(Collection.count).to eq 2
  end

  it 'only makes one collection object per call number' do
    cci.import(collections_csv, "/dev/null")
    expect(Collection.where(local_call_number: "MSS1218").count).to eq 1
    expect(Collection.where(local_call_number: "YELLOWBACKS").count).to eq 1
    cci.import(collections_csv, "/dev/null")
    expect(Collection.where(local_call_number: "MSS1218").count).to eq 1
    expect(Collection.where(local_call_number: "YELLOWBACKS").count).to eq 1
  end

  it 'makes a collection using Curate::CollectionType' do
    library_collection_type_gid = Curate::CollectionType.find_or_create_library_collection_type.gid
    expect(langmuir_collection.collection_type_gid).to eq library_collection_type_gid
  end

  it 'has all expected metadata' do
    langmuir_collection.reload
    expect(langmuir_collection.title).to eq ["Robert Langmuir African American Photograph Collection"]
    expect(langmuir_collection.institution).to eq "Emory University"
    expect(langmuir_collection.holding_repository).to eq ["Stuart A. Rose Manuscript, Archives, and Rare Book Library"]
    expect(langmuir_collection.administrative_unit).to eq ["Stuart A. Rose Manuscript, Archives, and Rare Book Library"]
    expect(langmuir_collection.contact_information).to match(/Rose Library/)
    expect(langmuir_collection.abstract).to match(/Collection of photographs/)
    expect(langmuir_collection.primary_language).to eq "English"
    expect(langmuir_collection.local_call_number).to eq "MSS1218"
    expect(langmuir_collection.keywords).to contain_exactly("Keyword 1", "Keyword 2")
    expect(langmuir_collection.subject_topics).to include("Photography--United States--History--19th century")
    expect(langmuir_collection.subject_names).to include("Name 2")
    expect(langmuir_collection.subject_geo).to include("Place 2")
    expect(langmuir_collection.subject_time_periods).to include("Era 2")
    expect(langmuir_collection.creator).to eq ["Langmuir, Robert, collector"]
    expect(langmuir_collection.contributors).to include("Fake Contributor")
    expect(langmuir_collection.notes).to include("Fake Note")
    expect(langmuir_collection.rights_documentation).to eq "http://rightsstatements.org/vocab/InC-NC/1.0/"
    expect(langmuir_collection.internal_rights_note).to include("Fake Internal Rights Note")
    expect(langmuir_collection.sensitive_material).to include("No")
    expect(langmuir_collection.staff_notes).to include("Fake Staff Note")
    expect(langmuir_collection.system_of_record_ID).to include("Fake System of Record ID")
    expect(langmuir_collection.emory_ark).to include("Fake legacy ark")
    expect(langmuir_collection.primary_repository_ID).to include("Fake primary repository ID")
    expect(langmuir_collection.finding_aid_link).to include("http://findingaid.org/langmuir")
  end

  it 'does not override existing collection metadata' do
    langmuir_collection.reload
    langmuir_collection.title = ["New Langmuir Title"]
    langmuir_collection.save
    yellowbacks_collection.reload
    yellowbacks_collection.abstract = "New Yellowbacks Abstract"
    yellowbacks_collection.save
    cci.import(collections_csv, "/dev/null")
    expect(Collection.where(local_call_number: "MSS1218").first.title).to eq ["New Langmuir Title"]
    expect(Collection.where(local_call_number: "YELLOWBACKS").first.abstract).to eq "New Yellowbacks Abstract"
  end
end
