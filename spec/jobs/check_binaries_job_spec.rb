# frozen_string_literal: true
require 'rails_helper'

RSpec.describe CheckBinariesJob, :clean do
  let(:csv)         { IO.read(File.join("config/emory/check_binaries_results.csv")) }
  let(:file)        { File.open(fixture_path + '/book_page/0003_preservation_master.tif') }
  let(:file_set)    { FactoryBot.create(:file_set) }

  context "file is present in s3" do
    before do
      Hydra::Works::AddFileToFileSet.call(file_set, file, :preservation_master_file)
      allow(Aws::S3::Resource).to receive_message_chain(:new, :bucket, :object, :exists?).and_return(true)
      described_class.perform_now('example-bucket', file_set.id)
    end

    it "finds file in s3 correctly" do
      expect(csv).not_to include(file_set.files.first.id)
    end
  end

  context "file is missing in s3" do
    before do
      Hydra::Works::AddFileToFileSet.call(file_set, file, :preservation_master_file)
      allow(Aws::S3::Resource).to receive_message_chain(:new, :bucket, :object, :exists?).and_return(false)
      described_class.perform_now('example-bucket', file_set.id)
    end

    it "cannot find file in s3 and adds to csv" do
      expect(csv).to include(file_set.files.first.id)
    end
  end
end
