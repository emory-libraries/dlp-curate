# frozen_string_literal: true
require 'rails_helper'

RSpec.describe YellowbackPreprocessor do
  before :all do
    # running #merge is expensive, only set it up and run it once and then check the results
    yellowback_pull_list_sample = File.join(fixture_path, 'csv_import', 'yellowbacks', 'yellowbacks_pull_list.csv')
    alma_export_sample = File.join(fixture_path, 'csv_import', 'yellowbacks', 'yellowbacks_marc.xml')
    preprocessor = described_class.new(yellowback_pull_list_sample, alma_export_sample)
    preprocessor.merge
  end

  after :all do
    test_csv = File.join(fixture_path, 'csv_import', 'yellowbacks', 'yellowbacks_pull_list-merged.csv')
    File.delete(test_csv) if File.exist?(test_csv)
  end

  # each test inspects the output of the pre-processor, read into the import_rows CSV::Table object
  let(:import_rows) { CSV.read(File.join(fixture_path, 'csv_import', 'yellowbacks', 'yellowbacks_pull_list-merged.csv'), headers: true).by_row! }

  let(:shakespeare_start) { 1 }
  let(:twain_start)   { shakespeare_start + 198 + 3 }
  let(:moths1_start)  { twain_start + 198 + 3 }
  let(:moths2_start)  { moths1_start + 194 + 3 }
  let(:pdf_offset)    { 1 }
  let(:ocr_offset)    { 2 }
  let(:pages_offset)  { ocr_offset }
  let(:moths2_pages)  { 194 }

  it 'processes the expected number of rows' do
    expect(import_rows.length).to eq(moths2_start + pdf_offset + ocr_offset + moths2_pages)
  end

  it 'processes the expected works', :aggregate_failures do
    expect(import_rows[0]['title']).to eq('Edge cases : miscellaneous & sundry') # Edge cases
    expect(import_rows[shakespeare_start]['title']).to eq('Shakespeare\'s comedy of The merchant of Venice') # Shakespeare's comedy of The merchant of Venice
    expect(import_rows[twain_start]['title']).to eq('Choice bits from Mark Twain.') # Choice bits from Mark Twain
    expect(import_rows[moths1_start]['title']).to eq('The common moths of England [Copy 2]') # The common moths of England
    expect(import_rows[moths2_start]['title']).to eq('The common moths of England [Copy 3]') # The common moths of England
  end

  it 'provides a deduplication key', :aggregate_failures do
    expect(import_rows[shakespeare_start]['deduplication_key']).to eq('7stsg') # Shakespeare's comedy of The merchant of Venice
    expect(import_rows[twain_start]['deduplication_key']).to eq('4c1gx') # Choice bits from Mark Twain
  end

  it 'adds filesets for PDFs', :aggregate_failures do
    shakespeare_pdf = import_rows[shakespeare_start + pdf_offset] # Shakespeare's comedy of The merchant of Venice
    expect(shakespeare_pdf['type']).to eq('fileset')
    expect(shakespeare_pdf['fileset_label']).to eq('PDF for volume')
    expect(shakespeare_pdf['preservation_master_file']).to eq('/Yellowbacks/lsdi2/ocm04416480-2987/ocm04416480/Images/Output/Output.pdf')
  end

  it 'adds filesets for volume-level OCR', :aggregate_failures do
    shakespeare_pdf = import_rows[shakespeare_start + ocr_offset] # Shakespeare's comedy of The merchant of Venice
    expect(shakespeare_pdf['type']).to eq('fileset')
    expect(shakespeare_pdf['fileset_label']).to eq('OCR Output for Volume')
    expect(shakespeare_pdf['preservation_master_file']).to eq('/Yellowbacks/lsdi2/ocm04416480-2987/ocm04416480/Images/Output/Output.xml')
  end

  it 'adds page-level filesets', :aggregate_failures do
    first_page = import_rows[shakespeare_start + pages_offset + 1] # Shakespeare's comedy of The merchant of Venice
    expect(first_page['type']).to eq('fileset')
    expect(first_page['fileset_label']).to eq('Page 1')
    expect(first_page['preservation_master_file']).to eq('/Yellowbacks/lsdi2/ocm04416480-2987/ocm04416480/Images/Output/0001.tif')
    expect(first_page['extracted']).to eq('/Yellowbacks/lsdi2/ocm04416480-2987/ocm04416480/Images/Output/0001.pos')
    expect(first_page['transcript_file']).to eq('/Yellowbacks/lsdi2/ocm04416480-2987/ocm04416480/Images/Output/0001.txt')
    last_page = import_rows[shakespeare_start + pages_offset + 198]
    expect(last_page['type']).to eq('fileset')
    expect(last_page['fileset_label']).to eq('Page 198')
    expect(last_page['preservation_master_file']).to eq('/Yellowbacks/lsdi2/ocm04416480-2987/ocm04416480/Images/Output/0198.tif')
    expect(last_page['extracted']).to eq('/Yellowbacks/lsdi2/ocm04416480-2987/ocm04416480/Images/Output/0198.pos')
    expect(last_page['transcript_file']).to eq('/Yellowbacks/lsdi2/ocm04416480-2987/ocm04416480/Images/Output/0198.txt')
  end

  it 'handles file paths correctly', :aggregate_failures do
    shakespeare_pdf = import_rows[shakespeare_start + pdf_offset] # Shakespeare's comedy of The merchant of Venice
    twain_pdf = import_rows[twain_start + 1] # Choice bits from Mark Twain
    expect(shakespeare_pdf['preservation_master_file']).to eq('/Yellowbacks/lsdi2/ocm04416480-2987/ocm04416480/Images/Output/Output.pdf')
    expect(twain_pdf['preservation_master_file']).to eq('/Yellowbacks/lsdi/diesel/lts_new/ocm05922290-1895/ocm05922290/Output/Output.pdf')
  end

  it 'sets the visibility value', :aggregate_failures do
    expect(import_rows[0]['visibility']).to eq('Emory Network') # Edge cases
    expect(import_rows[shakespeare_start]['visibility']).to eq('Public') # Shakespeare's comedy of The merchant of Venice
  end

  it 'sets the source_collection_id value', :aggregate_failures do
    expect(import_rows[0]['source_collection_id']).to eq('some_id_1') # Edge cases
    expect(import_rows[shakespeare_start]['source_collection_id']).to be_nil # Shakespeare's comedy of The merchant of Venice
  end
end
