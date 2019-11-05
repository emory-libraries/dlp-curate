# frozen_string_literal: true
require 'rails_helper'

RSpec.describe LangmuirPreprocessor do
  before :all do
    # running #merge is expensive, only set it up and run it once and then check the results
    langmuir_sample = File.join(fixture_path, 'csv_import', 'before_processing', 'langmuir-unprocessed.csv')
    preprocessor = described_class.new(langmuir_sample)
    preprocessor.merge
  end

  after :all do
    test_csv = File.join(fixture_path, 'csv_import', 'before_processing', 'langmuir-unprocessed-processed.csv')
    File.delete(test_csv) if File.exist?(test_csv)
  end

  # each test inspects the output of the pre-processor, read into the import_rows CSV::Table object
  let(:import_rows) { CSV.read(File.join(fixture_path, 'csv_import', 'before_processing', 'langmuir-unprocessed-processed.csv'), headers: true).by_row! }

  it 'outputs the expected number of rows' do
    expect(import_rows.length).to eq(17)
  end

  # this just repeats the csv data, but shows the testing pattern and titles used in subsequent tests
  it 'processes the expected works' do
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
    expect(import_rows[0]['type']).to eq('work') # City gates, St. Augustine, Florida
  end

  it 'creates a fileset row for each side/part' do
    expect(import_rows[13]['type']).to eq('fileset') # Advertising : Rafael's, gay 'n frisky
  end

  it 'uses Front/Back as fileset labels for two sided works' do
    expect(import_rows[1]['fileset_label']).to eq('Front') # City gates, St. Augustine, Florida
    expect(import_rows[2]['fileset_label']).to eq('Back') # City gates, St. Augustine, Florida
  end

  it 'uses Side # as fileset labels for multi-sided works' do
    expect(import_rows[13]['fileset_label']).to eq('Image 1') # Advertising : Rafael's, gay 'n frisky
    expect(import_rows[16]['fileset_label']).to eq('Image 4') # Advertising : Rafael's, gay 'n frisky
  end

  it 'attaches the ARCH file as the preservation_master_file' do
    expect(import_rows[2]['preservation_master_file']).to match(/ARCH/) # City gates, St. Augustine, Florida
  end

  it 'attaches the PROD file as the intermediate_file' do
    expect(import_rows[2]['intermediate_file']).to match(/PROD/) # City gates, St. Augustine, Florida
  end

  it 'attaches the expected files to the expected filesets in the expected order' do # Advertising : Rafael's, gay 'n frisky
    expect(import_rows[14]['fileset_label']).to eq('Image 2') # P0002
    expect(import_rows[14]['preservation_master_file']).to match('MSS1218_B028_I091_P0002_ARCH.tif') # ARCH
    expect(import_rows[15]['fileset_label']).to eq('Image 3') # P0003
    expect(import_rows[15]['intermediate_file']).to match('MSS1218_B028_I091_P0003_PROD.tif') # PROD
  end

  it 'includes the relative path in the file attachment' do
    expect(import_rows[7]['preservation_master_file']).to eq('./dmfiles/MARBL/Manuscripts/MSS_1218_Langmuir/ARCH/B071/MSS1218_B071_I207_P0001_ARCH.tif')
  end
end
