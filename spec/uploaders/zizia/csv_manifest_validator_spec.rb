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
  let(:header) do
    %w[
      title
      administrative_unit
      holding_repository
      content_type
      rights_statement_text
      rights_statement
      data_classification
      date_created
    ]
  end
  let(:row2) do
    [
      'Advertising, High Boy cigarettes',
      'Emory University Archives',
      'Stuart A. Rose Manuscript, Archives, and Rare Book Library',
      'http://id.loc.gov/vocabulary/resourceTypes/img',
      'Emory University does not control copyright for this image.',
      'http://rightsstatements.org/vocab/InC/1.0/',
      'Confidential',
      '194X'
    ]
  end
  let(:file_path) { "tmp/test.csv" }
  let(:csv_file) do
    CSV.open(file_path, "w") do |csv|
      rows.each do |row|
        csv << row
      end
    end
    file_path
  end
  let(:rows) { [header, row2] }

  after { File.delete(file_path) }

  context 'a valid CSV file' do
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
    it 'has an error' do
      allow(CSV).to receive(:read).and_raise(CSV::MalformedCSVError, 'abcdefg')
      validator.validate
      expect(validator.errors).to contain_exactly(
        "We are unable to read this CSV file."
      )
    end
  end

  context 'a CSV that is missing required headers' do
    let(:header) { ["administrative_unit"] }
    let(:row2) { ["Emory University Archives"] }

    it 'has an error for every missing header' do
      validator.validate
      expected_errors = ["title"]
      expected_errors.each do |error|
        matches = validator.errors.map { |e| e.match(error) }
        expect(matches.compact).not_to be_empty
      end
    end
  end

  context 'a CSV that is missing headers required by the edit form' do
    let(:header) { ["title"] }
    let(:row2) { ["Advertising, High Boy cigarettes"] }

    it 'has a warning for every missing header' do
      validator.validate
      expected_warnings = REQUIRED_FIELDS_ON_FORM.map(&:to_s) - ["title"]
      expected_warnings.each do |warning|
        matches = validator.warnings.map { |e| e.match(warning) }
        expect(matches.compact).not_to be_empty
      end
    end
  end

  context 'a CSV with invalid administrative unit data' do
    let(:row2) { ["Title1", "Emory University Archives", "", "", "", "", "", "", ""] }
    let(:row3) { ["Title2", "Fake Administrative Unit", "", "", "", "", "", "", ""] }
    let(:rows) { [header, row2, row3] }

    it 'has a warning' do
      validator.validate
      expected_warning = "Invalid administrative_unit in row 3: fake administrative unit"
      expect(validator.warnings).to include(expected_warning)
    end
  end

  context 'a CSV with duplicate headers' do
    let(:header) do
      %w[
        title
        local_call_number
        local_call_number
        administrative_unit
        holding_repository
        content_type
        rights_statement_text
        rights_statement
        data_classification
        date_created
      ]
    end

    it 'has an error' do
      validator.validate
      expect(validator.errors.first).to match(/Duplicate column name/)
      expect(validator.errors.first).to match(/local_call_number/)
    end
  end

  # These will produce actual errors. Other metadata mistakes are warnings.
  context 'a CSV that is missing required values' do
    let(:row2) { ["", "", "", "", "", "", "", "", ""] }

    it 'has errors' do
      validator.validate
      expect(validator.errors.first).to match(/row 2/)
      expect(validator.errors.first).to match(/title/)
    end
  end

  context 'a CSV that has extra headers' do
    let(:extra_headers) { header + ["another_header_1", "another_header_2"] }
    let(:rows) { [extra_headers, row2] }
    it 'has a warning' do
      validator.validate
      expect(validator.warnings).to include(
        'The field name "another_header_1" is not supported.  This field will be ignored, and the metadata for this field will not be imported.',
        'The field name "another_header_2" is not supported.  This field will be ignored, and the metadata for this field will not be imported.'
      )
    end
  end

  context 'a CSV with the wrong number of values in a row' do
    let(:rows) { [header, wrong_number_of_values_row] }
    context "too many values in a row" do
      let(:wrong_number_of_values_row) { row2 + ["whatever"] }
      it "raises a warning" do
        validator.validate
        expected_warning = "row 2: too many fields in the row"
        expect(validator.warnings).to include(expected_warning)
      end
    end
    context "too few values in a row" do
      let(:wrong_number_of_values_row) { ["whatever", "whatever"] }
      it "raises a warning" do
        validator.validate
        expected_warning = "row 2: too few fields in the row"
        expect(validator.warnings).to include(expected_warning)
      end
    end
  end

  context 'either string values or URIs in resource type field' do
    context 'with a string' do
      it 'recognizes a valid string for resource type' do
        row2[3] = "Still image"
        validator.validate
        expect(validator.errors).to eq []
        expect(validator.warnings).to eq []
      end
    end
    context 'with a uri' do
      it 'recognizes a valid uri for resource type' do
        validator.validate
        expect(validator.errors).to eq []
        expect(validator.warnings).to eq []
      end
    end
  end

  context 'a CSV with invalid values in controlled-vocabulary fields' do
    it 'has warnings' do
      row2[3] = "http://id.loc.gov/vocabulary/resourcetypes/foobar"
      validator.validate
      expect(validator.warnings).to include(
        "Invalid content_type in row 2: http://id.loc.gov/vocabulary/resourcetypes/foobar"
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
