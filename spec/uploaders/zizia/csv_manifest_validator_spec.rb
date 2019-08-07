# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Zizia::CsvManifestValidator, type: :model do
  let(:validator) { described_class.new(manifest) }
  let(:manifest) { csv_import.manifest }
  let(:user) { FactoryBot.build(:user) }
  let(:csv_import) do
    import = Zizia::CsvImport.new
    File.open(csv_file) { |f| import.manifest = f }
    import
  end

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('IMPORT_FILE_PATH').and_return(fixture_path)

    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with(File.join(ENV['IMPORT_FILE_PATH'], 'Masters/dlmasters/clusc_1_1_00010432a.tif')).and_return(true)
  end

  context 'a valid CSV file' do
    let(:csv_file) { File.join(fixture_path, 'csv_import', 'good', 'langmuir_tiny.csv') }

    it 'has no errors' do
      expect(validator.errors).to eq []
    end

    it 'has no warnings' do
      expect(validator.warnings).to eq []
    end

    it 'returns the record count' do
      validator.validate
      expect(validator.record_count).to eq 1
    end
  end

  context 'a file that can\'t be parsed' do
    let(:csv_file) { File.join(fixture_path, 'csv_import', 'good', 'langmuir_tiny.csv') }

    it 'has an error' do
      allow(CSV).to receive(:read).and_raise(CSV::MalformedCSVError, 'abcdefg')
      validator.validate
      expect(validator.errors).to contain_exactly(
        "We are unable to read this CSV file."
      )
    end
  end

  context 'a CSV that is missing required headers' do
    let(:csv_file) { File.join(fixture_path, 'csv_import', 'csv_files_with_problems', 'missing_headers.csv') }

    it 'has an error for every missing header' do
      validator.validate
      expected_errors = ["title", "content_type"]
      expected_errors.each do |error|
        matches = validator.errors.map { |e| e.match(error) }
        expect(matches.compact).not_to be_empty
      end
    end
  end

  context 'a CSV with duplicate headers' do
    let(:csv_file) { File.join(fixture_path, 'csv_import', 'csv_files_with_problems', 'duplicate_headers.csv') }

    it 'has an error' do
      validator.validate
      expect(validator.errors.first).to match(/Duplicate column name/)
      expect(validator.errors.first).to match(/Call Number/)
    end
  end

  context 'a CSV that is missing required values' do
    let(:csv_file) { File.join(fixture_path, 'csv_import', 'csv_files_with_problems', 'missing_values.csv') }

    it 'has errors' do
      validator.validate
      expect(validator.errors.first).to match(/row 2/)
      expect(validator.errors.first).to match(/Title/)
    end
  end

  context 'a CSV that has extra headers' do
    let(:csv_file) { File.join(fixture_path, 'csv_import', 'csv_files_with_problems', 'extra_headers.csv') }

    it 'has a warning' do
      validator.validate
      expect(validator.warnings).to include(
        'The field name "another_header_1" is not supported.  This field will be ignored, and the metadata for this field will not be imported.',
        'The field name "another_header_2" is not supported.  This field will be ignored, and the metadata for this field will not be imported.'
      )
    end
  end

  context 'either string values or URIs in resource type field' do
    let(:csv_file) { File.join(fixture_path, 'csv_import', 'good', 'langmuir_tiny.csv') }
    it 'recognizes a valid string for resource type' do
      validator.validate
      expect(validator.errors).to eq []
      expect(validator.warnings).to eq []
    end
  end

  context 'a CSV with invalid values in controlled-vocabulary fields' do
    let(:csv_file) { File.join(fixture_path, 'csv_import', 'csv_files_with_problems', 'invalid_values.csv') }

    it 'has warnings' do
      validator.validate
      expect(validator.errors).to include(
        "Invalid Desc   Type Of Resource in row 2: invalid resource type"
      )
    end
  end

  # We don't yet know how we plan to find the files, so removing this check for now.
  # context 'when the csv has a missing file' do
  #   let(:csv_file) { 'spec/fixtures/example-missingimage.csv' }
  #
  #   it 'has warnings' do
  #     allow(File).to receive(:exist?).with(path).and_return(false)
  #     validator.validate
  #     expect(validator.warnings).to include("Row 2: Rows contain a File Name that does not exist. Incorrect values may be imported.")
  #   end
  #
  #   it 'doesn\'t warn about files that aren\'t missing' do
  #     allow(File).to receive(:exist?).with(path).and_return(true)
  #     validator.validate
  #     expect(validator.warnings).not_to include("Row 2: cannot find '#{path}'")
  #   end
  # end
end
