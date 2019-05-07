require 'rails_helper'

RSpec.describe AttachFilesToFileSetJob, perform_enqueued: [AttachFilesToFileSetJob] do
  let(:file1) { File.open(fixture_path + '/world.png') }
  let(:file2) { File.open(fixture_path + '/image.jp2') }
  let(:uploaded_file1) { FactoryBot.build(:uploaded_file, file: file1) }
  let(:uploaded_file2) { FactoryBot.build(:uploaded_file, file: file2) }
  let(:file_set) { FactoryBot.create(:file_set) }
  let(:generic_work) { FactoryBot.create(:public_generic_work) }
  let(:type) { :original_file }
  let(:user) { FactoryBot.create(:user) }

  describe 'a file attacher', perform_enqueued: [AttachFilesToFileSetJob, IngestJob] do
    it 'attaches files to file_set' do
      described_class.perform_now(generic_work, file_set, uploaded_file1, type)
      described_class.perform_now(generic_work, file_set, uploaded_file2, type)
      file_set.reload
      expect(file_set.files.size).to eq(2)
    end
  end
end
