# frozen_string_literal: true
require 'rails_helper'

RSpec.describe DamsPreprocessor do
  before :all do
    # running #merge is expensive, only set it up and run it once and then check the results
    dams_sample = File.join(fixture_path, 'csv_import', 'dams', 'dams-unprocessed.csv')
    preprocessor = described_class.new(dams_sample)
    preprocessor.merge
  end

  after :all do
    test_csv = File.join(fixture_path, 'csv_import', 'dams', 'dams-unprocessed-processed.csv')
    File.delete(test_csv) if File.exist?(test_csv)
  end

  # each test inspects the output of the pre-processor, read into the import_rows CSV::Table object
  let(:processed_csv) { File.join(fixture_path, 'csv_import', 'dams', 'dams-unprocessed-processed.csv') }
  let(:import_rows) { CSV.read(processed_csv, headers: true).by_row! }
  let(:unparsed_rows) { File.read(processed_csv) }

  it 'outputs the expected number of rows' do
    expect(import_rows.length).to eq(24)
  end

  # this just repeats the csv data, but shows the testing pattern and titles used in subsequent tests
  it 'processes the expected works', :aggregate_failures do
    expect(import_rows[0]['title']).to eq("Dr. C. H. Fitch's Prescription Scale owned by Dr. William Mundy")
    expect(import_rows[4]['title']).to eq("Civil War-era brass screw tourniquet used to control bleeding in a limb or extremity")
    expect(import_rows[21]['title']).to eq("Scarificator medical device used for bloodletting")
  end

  it 'identifies the source row from the original csv' do
    expect(import_rows[0]['source_row']).to eq('2') # Fitch's Prescription
  end

  it 'creates a deduplication_key' do
    expect(import_rows[0]['deduplication_key']).to eq('HS-S023_B001') # Fitch's Prescription
  end

  it 'sets the row type' do
    expect(import_rows[0]['type']).to eq('work') # Fitch's Prescription
  end

  it 'creates a fileset row for each part' do
    expect(import_rows[8]['type']).to eq('fileset') # Medical News
  end

  it 'uses image # as fileset labels for all works' do
    expect(import_rows[8]['fileset_label']).to eq('Image 1') # Medical News
    expect(import_rows[10]['fileset_label']).to eq('Image 3') # Medical News
  end

  it 'has the expected row length', :aggregate_failures do
    header_fields = import_rows.headers
    metadata_row_fields = CSV.parse(unparsed_rows.lines[7]).first # Medical News
    fileset_row_fields = CSV.parse(unparsed_rows.lines[10]).first
    # The following has changed since we are automatically including source_collection_id
    # if the field is not in the input csv.
    expect(metadata_row_fields.size).to eq(header_fields.size)
    expect(fileset_row_fields.size).to eq(header_fields.size)
  end

  it 'attaches the expected files to the expected filesets in the expected order', :aggregate_failures do # Medical News
    expect(import_rows[10]['fileset_label']).to eq('Image 3') # P0003
    expect(import_rows[10]['preservation_master_file']).to match('HS-S023_B003_P003.tif')
  end

  it 'includes the relative path in the file attachment' do
    expect(import_rows[8]['preservation_master_file']).to eq('dmfiles/Libraries/Health_Sciences/HS-S023/HS-S023_B003_P001.tif')
  end

  it 'includes source_collection_id column when not in input csv' do
    import_rows.each do |row|
      expect(row.headers).to include('source_collection_id')
      expect(row['source_collection_id']).to be_nil
    end
  end
end
