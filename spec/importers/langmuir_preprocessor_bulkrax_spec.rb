# frozen_string_literal: true
require 'rails_helper'

RSpec.describe LangmuirPreprocessor do
  before :all do
    # running #merge is expensive, only set it up and run it once and then check the results
    langmuir_sample = File.join(fixture_path, 'csv_import', 'langmuir', 'langmuir-unprocessed.csv')
    preprocessor = described_class.new(langmuir_sample, 'bulkrax')
    preprocessor.merge
  end

  after :all do
    test_csv = File.join(fixture_path, 'csv_import', 'langmuir', 'langmuir-unprocessed-processed.csv')
    File.delete(test_csv) if File.exist?(test_csv)
  end

  # each test inspects the output of the pre-processor, read into the import_rows CSV::Table object
  let(:processed_csv) { File.join(fixture_path, 'csv_import', 'langmuir', 'langmuir-unprocessed-processed.csv') }
  let(:import_rows) { CSV.read(processed_csv, headers: true).by_row! }
  let(:unparsed_rows) { File.read(processed_csv) }

  it 'outputs the expected number of rows' do
    expect(import_rows.length).to eq(17)
  end

  # this just repeats the csv data, but shows the testing pattern and titles used in subsequent tests
  it 'processes the expected works', :aggregate_failures do
    expect(import_rows[0]['title']).to eq('City gates, St. Augustine, Florida') # City gates, St. Augustine, Florida
    expect(import_rows[3]['title']).to eq('A disappearing mode of transportation, Palm Beach, Florida') # A disappearing mode of transportation, Palm Beach, Florida
    expect(import_rows[6]['title']).to eq('The old city gate, St. Augustine, Fla.') # The old city gate, St. Augustine, Fla.
    expect(import_rows[9]['title']).to eq('Oldest wooden school house, St. Augustine, Florida') # Oldest wooden school house, St. Augustine, Florida
    expect(import_rows[12]['title']).to eq('Advertising : Rafael\'s, gay \'n frisky') # Advertising : Rafael's, gay 'n frisky
  end

  it 'identifies the source row from the original csv' do
    expect(import_rows[0]['source_row']).to eq('2') # City gates, St. Augustine, Florida
  end

  it 'skips blank lines in the original csv & lists works in proper order' do
    expect(import_rows[12]['source_row']).to eq('29') # Advertising : Rafael's, gay 'n frisky - work metadata
  end

  it 'creates a deduplication_key' do
    expect(import_rows[0]['deduplication_key']).to eq('MSS1218_B071_I205') # City gates, St. Augustine, Florida
  end

  it 'sets the row type' do
    expect(import_rows[0]['type']).to be_nil # City gates, St. Augustine, Florida
    expect(import_rows[0]['model']).to eq('CurateGenericWork')
  end

  it 'creates a fileset row for each side/part' do
    expect(import_rows[13]['type']).to be_nil # Advertising : Rafael's, gay 'n frisky
    expect(import_rows[13]['model']).to eq('FileSet')
  end

  it 'uses the source_collection_id for parent on a work' do
    expect(import_rows[0]['parent']).to eq(import_rows[0]['source_collection_id'])
  end

  it 'uses the work dedupe key for parent on filesets' do
    expect(import_rows[1]['parent']).to eq(import_rows[0]['deduplication_key'])
  end

  it 'uses Front/Back as fileset labels for two sided works' do
    expect(import_rows[1]['fileset_label']).to be_nil # City gates, St. Augustine, Florida
    expect(import_rows[1]['title']).to eq('Front')
    expect(import_rows[2]['fileset_label']).to be_nil # City gates, St. Augustine, Florida
    expect(import_rows[2]['title']).to eq('Back')
  end

  it 'uses Side # as fileset labels for multi-sided works' do
    expect(import_rows[13]['fileset_label']).to be_nil # Advertising : Rafael's, gay 'n frisky
    expect(import_rows[13]['title']).to eq('Image 1')
    expect(import_rows[16]['fileset_label']).to be_nil # Advertising : Rafael's, gay 'n frisky
    expect(import_rows[16]['title']).to eq('Image 4')
  end

  it 'has the expected row length', :aggregate_failures do
    header_fields = import_rows.headers
    metadata_row_fields = CSV.parse(unparsed_rows.lines[13]).first # Advertising : Rafael's, gay 'n frisky
    fileset_row_fields = CSV.parse(unparsed_rows.lines[14]).first
    # The following has changed since we are automatically including source_collection_id
    # if the field is not in the input csv.
    expect(metadata_row_fields.size).to eq(header_fields.size - 1)
    expect(fileset_row_fields.size).to eq(header_fields.size)
  end

  it 'has the filename found in file in file_types for filesets' do
    expect(import_rows[1]['file_types']).to include(import_rows[1]['file'])
      .and include(':preservation_master_file')
  end

  it 'attaches the ARCH file as the preservation_master_file' do
    expect(import_rows[2]['preservation_master_file']).to match(/ARCH/) # City gates, St. Augustine, Florida
  end

  it 'attaches the PROD file as the intermediate_file' do
    expect(import_rows[2]['intermediate_file']).to match(/PROD/) # City gates, St. Augustine, Florida
  end

  it 'attaches the expected files to the expected filesets in the expected order', :aggregate_failures do # Advertising : Rafael's, gay 'n frisky
    expect(import_rows[14]['fileset_label']).to be_nil # P0002
    expect(import_rows[14]['title']).to eq('Image 2')
    expect(import_rows[14]['deduplication_key']).to be_empty
    expect(import_rows[14]['parent']).to eq('MSS1218_B028_I091')
    expect(import_rows[14]['pcdm_use']).to eq('Primary Content')
    expect(import_rows[14]['file']).to eq('MSS1218_B028_I091_P0002_ARCH.tif')
    expect(import_rows[14]['file_types']).to eq('MSS1218_B028_I091_P0002_ARCH.tif:preservation_master_file')
    expect(import_rows[14]['preservation_master_file']).to match('MSS1218_B028_I091_P0002_ARCH.tif') # ARCH

    expect(import_rows[15]['fileset_label']).to be_nil # P0003
    expect(import_rows[15]['title']).to eq('Image 3')
    expect(import_rows[15]['deduplication_key']).to be_empty
    expect(import_rows[15]['parent']).to eq('MSS1218_B028_I091')
    expect(import_rows[15]['pcdm_use']).to eq('Primary Content')
    expect(import_rows[15]['file']).to eq('MSS1218_B028_I091_P0003_PROD.tif')
    expect(import_rows[15]['file_types']).to eq('MSS1218_B028_I091_P0003_PROD.tif:intermediate_file')
    expect(import_rows[15]['intermediate_file']).to match('MSS1218_B028_I091_P0003_PROD.tif') # PROD
  end

  it 'includes the relative path in the file attachment' do
    expect(import_rows[7]['preservation_master_file']).to eq('dmfiles/MARBL/Manuscripts/MSS_1218_Langmuir/ARCH/B071/MSS1218_B071_I207_P0001_ARCH.tif')
  end

  it 'includes source_collection_id column when not in input csv' do
    import_rows.each do |row|
      expect(row.headers).to include('source_collection_id')
      expect(row['source_collection_id']).to be_nil
    end
  end

  context 'file has source_collection_id defined' do
    it 'shows assigned values in processed csv' do
      source_langmuir_sample = File.join(fixture_path, 'csv_import', 'langmuir', 'langmuir-unprocessed-with-source-id.csv')
      preprocessor = described_class.new(source_langmuir_sample, 'bulkrax')
      preprocessor.merge
      source_processed_csv = File.join(fixture_path, 'csv_import', 'langmuir', 'langmuir-unprocessed-with-source-id-processed.csv')
      source_import_rows = CSV.read(source_processed_csv, headers: true).by_row!
      works_with_source_ids = source_import_rows.select { |r| r['source_collection_id'] == "some_id_1" }

      expect(source_import_rows.headers).to include('source_collection_id')
      expect(works_with_source_ids.size).to eq(5)

      File.delete(source_processed_csv) if File.exist?(source_processed_csv)
    end
  end
end
