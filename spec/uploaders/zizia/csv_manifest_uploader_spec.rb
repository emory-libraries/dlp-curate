# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Zizia::CsvManifestUploader, type: :model do
  let(:uploader) { csv_import.manifest }
  let(:csv_import) do
    import = Zizia::CsvImport.new
    File.open(csv_file) { |f| import.manifest = f }
    import
  end
  let(:user) { FactoryBot.build(:user) }

  before do
    allow(File).to receive(:exist?).and_call_original
  end

  context 'a valid CSV file' do
    let(:csv_file) { File.join(fixture_path, 'csv_import', 'good', 'langmuir_tiny.csv') }

    it 'has no errors' do
      expect(uploader.errors).to eq []
    end

    it 'has no warnings' do
      expect(uploader.warnings).to eq []
    end

    it 'has a correct record count' do
      expect(uploader.records).to eq 1
    end
  end
end
