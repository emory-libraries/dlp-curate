# frozen_string_literal: true
require 'rails_helper'

RSpec.describe YellowbackPreprocessor do
  context 'not adding extra lines' do
    before :all do
      # running #merge is expensive, only set it up and run it once and then check the results
      yearbook_pull_list_sample = File.join(fixture_path, 'csv_import', 'yearbooks', 'Yearbooks-LIMB.csv')
      alma_export_sample = File.join(fixture_path, 'csv_import', 'yearbooks', 'yearbooks_marc.xml')
      preprocessor = described_class.new(yearbook_pull_list_sample, alma_export_sample, 'bulkrax', :limb, 1, false, false)
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
      work_models = [emocad_1924_start, memory_1981_start, memory_2003_start, campus_1981_start,
                     campus_1985_start, campus_1989_start].map { |w| import_rows[w]['model'] }.uniq
      expect(import_rows[emocad_1924_start]['title']).to eq('Emocad. [1924]') # Emocad '24
      expect(import_rows[memory_1981_start]['title']).to eq('Memory [1981]') # Memory '81
      expect(import_rows[memory_2003_start]['title']).to eq('Memory [2003]') # Memory '03
      expect(import_rows[campus_1981_start]['title']).to eq('The campus. [1981]') # The Campus '81
      expect(import_rows[campus_1985_start]['title']).to eq('The campus. [1985]') # The Campus '85
      expect(import_rows[campus_1989_start]['title']).to eq('The campus. [1989]') # The Campus '89

      expect(work_models).to eq(['CurateGenericWork'])
    end

    it 'provides a deduplication key', :aggregate_failures do
      expect(import_rows[memory_1981_start]['deduplication_key']).to eq('050000087539') # Memory '81
      expect(import_rows[campus_1985_start]['deduplication_key']).to eq('000011909908') # The Campus '85
    end

    it 'has the expected number of transcript rows' do
      transcript_rows = import_rows.select { |r| r['title'] == 'Transcript for Volume' }

      expect(transcript_rows.size).to be_zero
    end

    it 'has the expected number of OCR rows' do
      ocr_rows = import_rows.select { |r| r['title'] == 'OCR Output for Volume' }

      expect(ocr_rows.size).to eq(1)
    end

    it 'adds filesets for PDFs', :aggregate_failures do
      campus_1981_pdf = import_rows[campus_1981_start + pdf_offset] # The Campus '81
      expect(campus_1981_pdf['type']).to be_nil
      expect(campus_1981_pdf['model']).to eq('FileSet')
      expect(campus_1981_pdf['fileset_label']).to be_nil
      expect(campus_1981_pdf['title']).to eq('PDF for volume')
      expect(campus_1981_pdf['deduplication_key']).to be_empty
      expect(campus_1981_pdf['parent']).to eq('000011743488')
      expect(campus_1981_pdf['pcdm_use']).to eq('Primary Content')
      expect(campus_1981_pdf['file']).to eq('000011743488.pdf')
      expect(campus_1981_pdf['file_types']).to eq('000011743488.pdf:preservation_master_file')
      expect(campus_1981_pdf['preservation_master_file']).to include('lsdi2/ftp/000011743488/PDF/000011743488.pdf')
    end

    it 'adds filesets for volume-level METS', :aggregate_failures do
      campus_1985_mets = import_rows[campus_1985_start + mets_offset] # The Campus '85
      expect(campus_1985_mets['type']).to be_nil
      expect(campus_1985_mets['model']).to eq('FileSet')
      expect(campus_1985_mets['fileset_label']).to be_nil
      expect(campus_1985_mets['title']).to eq('METS File')
      expect(campus_1985_mets['deduplication_key']).to be_empty
      expect(campus_1985_mets['parent']).to eq('000011909908')
      expect(campus_1985_mets['pcdm_use']).to eq('Supplemental Preservation')
      expect(campus_1985_mets['file']).to eq('000011909908.mets.xml')
      expect(campus_1985_mets['file_types']).to eq('000011909908.mets.xml:preservation_master_file')
      expect(campus_1985_mets['preservation_master_file']).to include('lsdi2/ftp/000011909908/METS/000011909908.mets.xml')
    end

    it 'adds filesets for volume-level OCR', :aggregate_failures do
      campus_1989_ocr = import_rows[campus_1989_start + ocr_offset] # The Campus '89
      expect(campus_1989_ocr['type']).to be_nil
      expect(campus_1989_ocr['model']).to eq('FileSet')
      expect(campus_1989_ocr['fileset_label']).to be_nil
      expect(campus_1989_ocr['title']).to eq('OCR Output for Volume')
      expect(campus_1989_ocr['deduplication_key']).to be_empty
      expect(campus_1989_ocr['parent']).to eq('000011853132')
      expect(campus_1989_ocr['pcdm_use']).to eq('Supplemental Content')
      expect(campus_1989_ocr['file']).to eq('Output.xml')
      expect(campus_1989_ocr['file_types']).to eq('Output.xml:preservation_master_file')
      expect(campus_1989_ocr['preservation_master_file']).to include('lsdi2/ocm25899106-4402/ocm25899106/Output/XML/Output.xml')
    end

    it 'skips volume-level OCR if pull list info is missing', :aggregate_failures do
      campus_1981_expected_ocr = import_rows[campus_1981_start + ocr_offset] # The Campus '81
      expect(campus_1981_expected_ocr['type']).to be_nil
      expect(campus_1981_expected_ocr['model']).to eq('FileSet')
      expect(campus_1981_expected_ocr['title']).not_to eq('OCR Output for Volume')
    end

    it 'adds page-level filesets', :aggregate_failures do
      first_page = import_rows[campus_1981_start + campus_81_offset + 1] # The Campus '81
      expect(first_page['type']).to be_nil
      expect(first_page['model']).to eq('FileSet')
      expect(first_page['fileset_label']).to be_nil
      expect(first_page['title']).to eq('Page 1')
      expect(first_page['deduplication_key']).to be_empty
      expect(first_page['parent']).to eq('000011743488')
      expect(first_page['pcdm_use']).to eq('Primary Content')
      expect(first_page['file']).to eq('00000001.tif;00000001.txt;00000001.xml')
      expect(first_page['file_types']).to eq(
        '00000001.tif:preservation_master_file|00000001.txt:transcript|00000001.xml:extracted_text'
      )
      expect(first_page['preservation_master_file']).to include('lsdi2/ftp/000011743488/TIFF/00000001.tif')
      expect(first_page['extracted']).to include('lsdi2/ftp/000011743488/ALTO/00000001.xml')
      expect(first_page['transcript_file']).to include('lsdi2/ftp/000011743488/OCR/00000001.txt')

      last_page = import_rows[campus_1981_start + campus_81_offset + 304]
      expect(last_page['type']).to be_nil
      expect(last_page['model']).to eq('FileSet')
      expect(last_page['fileset_label']).to be_nil
      expect(last_page['title']).to eq('Page 304')
      expect(last_page['deduplication_key']).to be_empty
      expect(last_page['parent']).to eq('000011743488')
      expect(last_page['pcdm_use']).to eq('Primary Content')
      expect(last_page['file']).to eq('00000304.tif;00000304.txt;00000304.xml')
      expect(last_page['file_types']).to eq(
        '00000304.tif:preservation_master_file|00000304.txt:transcript|00000304.xml:extracted_text'
      )
      expect(last_page['preservation_master_file']).to include('lsdi2/ftp/000011743488/TIFF/00000304.tif')
      expect(last_page['extracted']).to include('lsdi2/ftp/000011743488/ALTO/00000304.xml')
      expect(last_page['transcript_file']).to include('lsdi2/ftp/000011743488/OCR/00000304.txt')
    end

    it 'adds handles base-0 numbered works correctly', :aggregate_failures do
      yearbook_pull_list_sample = File.join(fixture_path, 'csv_import', 'yearbooks', 'Yearbooks-LIMB-0.csv')
      alma_export_sample = File.join(fixture_path, 'csv_import', 'yearbooks', 'yearbooks_marc.xml')
      base0_preprocessor = described_class.new(yearbook_pull_list_sample, alma_export_sample, 'bulkrax', :limb, 0)
      base0_preprocessor.merge
      base0_import_rows = CSV.read(File.join(fixture_path, 'csv_import', 'yearbooks', 'Yearbooks-LIMB-0-merged.csv'), headers: true).by_row!

      first_page = base0_import_rows[emocad_1924_start + pages_offset + 1] # Emocad '24
      expect(first_page['type']).to be_nil
      expect(first_page['model']).to eq('FileSet')
      expect(first_page['fileset_label']).to be_nil
      expect(first_page['title']).to eq('Page 0')
      expect(first_page['deduplication_key']).to be_empty
      expect(first_page['parent']).to eq('050000084033')
      expect(first_page['pcdm_use']).to eq('Primary Content')
      expect(first_page['file']).to eq('00000000.tif;00000000.txt;00000000.xml')
      expect(first_page['file_types']).to eq(
        '00000000.tif:preservation_master_file|00000000.txt:transcript|00000000.xml:extracted_text'
      )
      expect(first_page['preservation_master_file']).to include('lsdi2/ftp/050000084033/TIFF/00000000.tif')
      expect(first_page['extracted']).to include('lsdi2/ftp/050000084033/ALTO/00000000.xml')
      expect(first_page['transcript_file']).to include('lsdi2/ftp/050000084033/OCR/00000000.txt')

      last_page = base0_import_rows[emocad_1924_start + pages_offset + 5]
      expect(last_page['type']).to be_nil
      expect(last_page['model']).to eq('FileSet')
      expect(last_page['fileset_label']).to be_nil
      expect(last_page['title']).to eq('Page 4')
      expect(last_page['deduplication_key']).to be_empty
      expect(last_page['parent']).to eq('050000084033')
      expect(last_page['pcdm_use']).to eq('Primary Content')
      expect(last_page['file']).to eq('00000004.tif;00000004.txt;00000004.xml')
      expect(last_page['file_types']).to eq(
        '00000004.tif:preservation_master_file|00000004.txt:transcript|00000004.xml:extracted_text'
      )
      expect(last_page['preservation_master_file']).to include('lsdi2/ftp/050000084033/TIFF/00000004.tif')
      expect(last_page['extracted']).to include('lsdi2/ftp/050000084033/ALTO/00000004.xml')
      expect(last_page['transcript_file']).to include('lsdi2/ftp/050000084033/OCR/00000004.txt')
    end
  end

  context 'adding extra lines' do
    before :all do
      # running #merge is expensive, only set it up and run it once and then check the results
      yearbook_pull_list_sample = File.join(fixture_path, 'csv_import', 'yearbooks', 'Yearbooks-LIMB.csv')
      alma_export_sample = File.join(fixture_path, 'csv_import', 'yearbooks', 'yearbooks_marc.xml')
      preprocessor = described_class.new(yearbook_pull_list_sample, alma_export_sample, 'bulkrax', :limb, 1, true, true)
      preprocessor.merge
    end

    after :all do
      test1_csv = File.join(fixture_path, 'csv_import', 'yearbooks', 'Yearbooks-LIMB-merged.csv')
      File.delete(test1_csv) if File.exist?(test1_csv)
    end

    # each test inspects the output of the pre-processor, read into the import_rows CSV::Table object
    let(:import_rows) { CSV.read(File.join(fixture_path, 'csv_import', 'yearbooks', 'Yearbooks-LIMB-merged.csv'), headers: true).by_row! }

    it 'has the expected number of transcript rows' do
      transcript_rows = import_rows.select { |r| r['title'] == 'Transcript for Volume' }

      expect(transcript_rows.size).to eq(6)
    end

    it 'has the expected number of OCR rows' do
      ocr_rows = import_rows.select { |r| r['title'] == 'OCR Output for Volume' }

      expect(ocr_rows.size).to eq(6)
    end
  end
end
