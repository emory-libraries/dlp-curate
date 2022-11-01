# frozen_string_literal: true
require 'rails_helper'

# Deprecation Warning: As of Curate v3, Zizia and this class will be removed.
RSpec.describe YellowbackPreprocessor do
  before :all do
    # running #merge is expensive, only set it up and run it once and then check the results
    yearbook_pull_list_sample = File.join(fixture_path, 'csv_import', 'yearbooks', 'Yearbooks-LIMB.csv')
    alma_export_sample = File.join(fixture_path, 'csv_import', 'yearbooks', 'yearbooks_marc.xml')
    preprocessor = described_class.new(yearbook_pull_list_sample, alma_export_sample, 'zizia', :limb)
    preprocessor.merge
  end

  after :all do
    test1_csv = File.join(fixture_path, 'csv_import', 'yearbooks', 'Yearbooks-LIMB-merged.csv')
    File.delete(test1_csv) if File.exist?(test1_csv)
    test0_csv = File.join(fixture_path, 'csv_import', 'yearbooks', 'Yearbooks-LIMB-0-merged.csv')
    File.delete(test0_csv) if File.exist?(test0_csv)
  end

  # each test inspects the output of the pre-processor, read into the import_rows CSV::Table object
  let(:import_rows) { CSV.read(File.join(fixture_path, 'csv_import', 'yearbooks', 'Yearbooks-LIMB-merged.csv'), headers: true).by_row! }

  let(:emocad_1924_start) { 0 }
  let(:memory_1981_start) { emocad_1924_start + 120 + 3 }
  let(:memory_2003_start) { memory_1981_start + 110 + 3 }
  let(:campus_1981_start) { memory_2003_start + 104 + 3 }
  let(:campus_1985_start) { campus_1981_start + 304 + 3 }
  let(:campus_1989_start) { campus_1985_start + 304 + 3 }
  let(:pdf_offset)        { 1 }
  let(:ocr_offset)        { 2 }
  let(:mets_offset)       { 2 }
  let(:pages_offset)      { ocr_offset }
  let(:campus_81_offset)  { 2 } # number of volume-level files before page level filesets appear
  let(:campus_1989_pages) { 356 }

  it 'processes the expected number of rows' do
    expect(import_rows.length).to eq(campus_1989_start + mets_offset + pages_offset + campus_1989_pages)
  end

  it 'processes the expected works', :aggregate_failures do
    expect(import_rows[emocad_1924_start]['title']).to eq('Emocad. [1924]') # Emocad '24
    expect(import_rows[memory_1981_start]['title']).to eq('Memory [1981]') # Memory '81
    expect(import_rows[memory_2003_start]['title']).to eq('Memory [2003]') # Memory '03
    expect(import_rows[campus_1981_start]['title']).to eq('The campus. [1981]') # The Campus '81
    expect(import_rows[campus_1985_start]['title']).to eq('The campus. [1985]') # The Campus '85
    expect(import_rows[campus_1989_start]['title']).to eq('The campus. [1989]') # The Campus '89
  end

  it 'provides a deduplication key', :aggregate_failures do
    expect(import_rows[memory_1981_start]['deduplication_key']).to eq('050000087539') # Memory '81
    expect(import_rows[campus_1985_start]['deduplication_key']).to eq('000011909908') # The Campus '85
  end

  it 'adds filesets for PDFs', :aggregate_failures do
    campus_1981_pdf = import_rows[campus_1981_start + pdf_offset] # The Campus '81
    expect(campus_1981_pdf['type']).to eq('fileset')
    expect(campus_1981_pdf['fileset_label']).to eq('PDF for volume')
    expect(campus_1981_pdf['preservation_master_file']).to include('lsdi2/ftp/000011743488/PDF/000011743488.pdf')
  end

  it 'adds filesets for volume-level METS', :aggregate_failures do
    campus_1985_mets = import_rows[campus_1985_start + mets_offset] # The Campus '85
    expect(campus_1985_mets['type']).to eq('fileset')
    expect(campus_1985_mets['fileset_label']).to eq('METS File')
    expect(campus_1985_mets['preservation_master_file']).to include('lsdi2/ftp/000011909908/METS/000011909908.mets.xml')
  end

  it 'adds filesets for volume-level OCR', :aggregate_failures do
    campus_1989_ocr = import_rows[campus_1989_start + ocr_offset] # The Campus '89
    expect(campus_1989_ocr['type']).to eq('fileset')
    expect(campus_1989_ocr['fileset_label']).to eq('OCR Output for Volume')
    expect(campus_1989_ocr['preservation_master_file']).to include('lsdi2/ocm25899106-4402/ocm25899106/Output/XML/Output.xml')
  end

  it 'skips volume-level OCR if pull list info is missing', :aggregate_failures do
    campus_1981_expected_ocr = import_rows[campus_1981_start + ocr_offset] # The Campus '81
    expect(campus_1981_expected_ocr['type']).to eq('fileset')
    expect(campus_1981_expected_ocr['fileset_label']).not_to eq('OCR Output for Volume')
  end

  it 'adds page-level filesets', :aggregate_failures do
    first_page = import_rows[campus_1981_start + campus_81_offset + 1] # The Campus '81
    expect(first_page['type']).to eq('fileset')
    expect(first_page['fileset_label']).to eq('Page 1')
    expect(first_page['preservation_master_file']).to include('lsdi2/ftp/000011743488/TIFF/00000001.tif')
    expect(first_page['extracted']).to include('lsdi2/ftp/000011743488/ALTO/00000001.xml')
    expect(first_page['transcript_file']).to include('lsdi2/ftp/000011743488/OCR/00000001.txt')
    last_page = import_rows[campus_1981_start + campus_81_offset + 304]
    expect(last_page['type']).to eq('fileset')
    expect(last_page['fileset_label']).to eq('Page 304')
    expect(last_page['preservation_master_file']).to include('lsdi2/ftp/000011743488/TIFF/00000304.tif')
    expect(last_page['extracted']).to include('lsdi2/ftp/000011743488/ALTO/00000304.xml')
    expect(last_page['transcript_file']).to include('lsdi2/ftp/000011743488/OCR/00000304.txt')
  end

  it 'adds handles base-0 numbered works correctly', :aggregate_failures do
    yearbook_pull_list_sample = File.join(fixture_path, 'csv_import', 'yearbooks', 'Yearbooks-LIMB-0.csv')
    alma_export_sample = File.join(fixture_path, 'csv_import', 'yearbooks', 'yearbooks_marc.xml')
    base0_preprocessor = described_class.new(yearbook_pull_list_sample, alma_export_sample, 'Yearbooks/Emory', :limb, 0)
    base0_preprocessor.merge
    base0_import_rows = CSV.read(File.join(fixture_path, 'csv_import', 'yearbooks', 'Yearbooks-LIMB-0-merged.csv'), headers: true).by_row!

    first_page = base0_import_rows[emocad_1924_start + pages_offset + 1] # Emocad '24
    expect(first_page['type']).to eq('fileset')
    expect(first_page['fileset_label']).to eq('Page 0')
    expect(first_page['preservation_master_file']).to include('lsdi2/ftp/050000084033/TIFF/00000000.tif')
    expect(first_page['extracted']).to include('lsdi2/ftp/050000084033/ALTO/00000000.xml')
    expect(first_page['transcript_file']).to include('lsdi2/ftp/050000084033/OCR/00000000.txt')
    last_page = base0_import_rows[emocad_1924_start + pages_offset + 5]
    expect(last_page['type']).to eq('fileset')
    expect(last_page['fileset_label']).to eq('Page 4')
    expect(last_page['preservation_master_file']).to include('lsdi2/ftp/050000084033/TIFF/00000004.tif')
    expect(last_page['extracted']).to include('lsdi2/ftp/050000084033/ALTO/00000004.xml')
    expect(last_page['transcript_file']).to include('lsdi2/ftp/050000084033/OCR/00000004.txt')
  end
end
