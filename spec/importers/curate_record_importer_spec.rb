# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CurateRecordImporter, :clean do
  subject(:curate_record_importer) { described_class.new }
  let(:arch_filename) { "MSS1218_B001_I001_P0001_ARCH.tif" }
  let(:prod_filename) { "MSS1218_B001_I001_P0001_PROD.tif" }

  it 'can be instantiated' do
    expect(curate_record_importer.class).to eq CurateRecordImporter
  end

  context "ARCH or PROD" do
    context "when the file is an ARCH file" do
      it 'can determine whether a file is an ARCH or PROD file' do
        file_type = curate_record_importer.file_type(arch_filename)
        expect(file_type).to eq "preservation_master_file"
      end
    end
    context "when the file is a PROD file" do
      it 'can determine whether a file is an ARCH or PROD file' do
        file_type = curate_record_importer.file_type(prod_filename)
        expect(file_type).to eq "intermediate_file"
      end
    end
    context "when the file is neither of these" do
      let(:fake_filename) { "whatever.tif" }
      it 'raises an exception' do
        expect { curate_record_importer.file_type(fake_filename) }.to raise_error RuntimeError
      end
    end
  end

  context "making a Hyrax::UploadedFile object" do
    it 'can attach a preservation_master_file' do
      huf = curate_record_importer.upload_preservation_master_file(arch_filename)
      expect(huf.class).to eq Hyrax::UploadedFile
      expect(huf.preservation_master_file.filename).to eq arch_filename
    end
    it 'can attach an intermediate_file' do
      huf = curate_record_importer.upload_intermediate_file(prod_filename)
      expect(huf.class).to eq Hyrax::UploadedFile
      expect(huf.intermediate_file.filename).to eq prod_filename
    end
  end

  context "making the right kind of file set for each file" do
    context "when the file is an ARCH file" do
      it 'makes an uploaded file object with a preservation_master_file' do
        curate_record_importer.upload_file(arch_filename)
        uploaded_file = Hyrax::UploadedFile.last
        expect(File.basename(uploaded_file.preservation_master_file.file.file)).to eq arch_filename
      end
    end
  end

  context "an existing record for a given call number" do
    let(:existing_work) { FactoryBot.create(:work_with_full_metadata, other_identifiers: ["MSS1218_B001_I001"]) }
    let(:record) do
      ir = Zizia::InputRecord.new
      ir.mapper = CurateMapper.new
      ir.mapper.metadata = { "Filename" => arch_filename }
      ir
    end
    it 'extracts a call number from a filename' do
      call_number = curate_record_importer.extract_call_number(arch_filename)
      expect(call_number).to eq "MSS1218_B001_I001"
    end
    it 'finds the existing record' do
      existing_work
      expect(curate_record_importer.find_existing_record(record)).to eq existing_work
    end
  end
end
