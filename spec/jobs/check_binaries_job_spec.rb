# frozen_string_literal: true
require 'rails_helper'

RSpec.describe CheckBinariesJob, :clean do
  let(:csv)           { IO.read(File.join("config/emory/check_binaries_results.csv")) }
  let(:file)          { File.open(fixture_path + '/book_page/0003_preservation_master.tif') }
  let(:file_set)      { FactoryBot.create(:file_set) }
  let(:file_set2)     { FactoryBot.create(:file_set) }
  let(:generic_work)  { FactoryBot.create(:public_work) }
  let(:generic_work2) { FactoryBot.create(:public_work) }

  before do
    generic_work.ordered_members << file_set
    generic_work.save
    generic_work2.ordered_members << file_set
    generic_work2.save
    generic_work.ordered_members << file_set2
    generic_work.save
  end

  context "file is present in s3" do
    before do
      Hydra::Works::AddFileToFileSet.call(file_set, file, :preservation_master_file)
      allow(Aws::S3::Resource).to receive_message_chain(:new, :bucket, :object, :exists?).and_return(true)
      described_class.perform_now('example-bucket', file_set.id)
    end

    it "finds file in s3 correctly" do
      expect(csv).not_to include("#{generic_work.id}, #{file_set.id}, #{file_set.files.first.id}, #{file_set.files.first.digest.first.to_s.partition('urn:sha1:').last}")
    end
  end

  context "file is missing in s3" do
    before do
      Hydra::Works::AddFileToFileSet.call(file_set, file, :preservation_master_file)
      allow(Aws::S3::Resource).to receive_message_chain(:new, :bucket, :object, :exists?).and_return(false)
      described_class.perform_now('example-bucket', file_set.id)
    end

    it "cannot find file in s3 and adds to csv" do
      expect(csv).to include("#{generic_work.id}|#{generic_work2.id},#{file_set.id},#{file_set.files.first.id},#{file_set.files.first.digest.first.to_s.partition('urn:sha1:').last}")
    end
  end

  context "run job on all file_sets when file_set_id is nil" do
    before do
      Hydra::Works::AddFileToFileSet.call(file_set, file, :preservation_master_file)
      Hydra::Works::AddFileToFileSet.call(file_set2, file, :preservation_master_file)
      allow(Aws::S3::Resource).to receive_message_chain(:new, :bucket, :object, :exists?).and_return(false)
      described_class.perform_now('example-bucket')
    end

    it "checks for all file_sets in s3" do
      expect(csv).to eq("#{generic_work.id}|#{generic_work2.id},#{file_set.id},#{file_set.files.first.id},#{file_set.files.first.digest.first.to_s.partition('urn:sha1:').last}
#{generic_work.id},#{file_set2.id},#{file_set2.files.first.id},#{file_set2.files.first.digest.first.to_s.partition('urn:sha1:').last}\n")
    end
  end
end
