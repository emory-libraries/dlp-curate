# frozen_string_literal: true
# [Hyrax-overwrite-v3.0.0.pre.beta3]
# We are only testing the `ingest_file` method here.

require 'rails_helper'

RSpec.describe JobIoWrapper, type: :model do
  describe "#ingest_file" do
    let(:user)          { FactoryBot.build(:user) }
    let(:file_set)      { FactoryBot.create(:file_set) }
    let(:pmf)           { File.open(fixture_path + '/book_page/0003_preservation_master.tif') }
    let(:inf)           { File.open(fixture_path + '/book_page/0003_intermediate.jp2') }
    let(:uploaded_file) { Hyrax::UploadedFile.new(user: user, file_set_uri: file_set.uri, preservation_master_file: pmf, intermediate_file: inf) }
    let(:args)          { { file_set: file_set, user: user, file: uploaded_file.preservation_master_file, relation: :preservation_master_file, preferred: :preservation_master_file } }
    let(:args2)         { { file_set: file_set, user: user, file: uploaded_file.intermediate_file, relation: :intermediate_file, preferred: :intermediate_file } }

    before do
      # ingest_file success
      described_class.create_with_varied_file_handling!(args).ingest_file
      # here we are mocking a `false` response from `file_actor.ingest_file`
      Hyrax::Actors::FileActor.any_instance.stub(:ingest_file).and_return(false)
      # ingest_file failure since `false` was returned
      described_class.create_with_varied_file_handling!(args2).ingest_file
      file_set.reload
    end

    it "saves preservation_events with proper outcomes" do
      expect(file_set.preservation_event.count).to eq 3
      expect(file_set.preservation_event.pluck(:event_details)).to include ['0003_intermediate.jp2 could not be submitted for preservation storage']
      expect(file_set.preservation_event.pluck(:event_details)).to include ['0003_preservation_master.tif submitted for preservation storage']
      expect(file_set.preservation_event.pluck(:outcome)).to include ['Failure']
      expect(file_set.preservation_event.pluck(:outcome)).to include ['Success']
    end
  end

  # spec taken from hyrax3-beta3
  # we are changing the output expectations on line 55 and 65 to integers in our test
  # which were previously strings in hyrax3-beta3. This is because we want our output
  # of the size method in job_io_wrapper to always be an integer.
  describe '#size' do
    let(:user) { FactoryBot.build(:user) }
    let(:path) { fixture_path + '/world.png' }
    let(:file_set_id) { 'bn999672v' }
    let(:args) { { file_set_id: file_set_id, user: user, path: path } }

    subject(:wrapper) { described_class.new(args) }

    context 'when file responds to :size' do
      before do
        allow(subject.file).to receive(:size).and_return(123)
        allow(subject.file).to receive(:respond_to?).with(:size).and_return(true)
        allow(subject.file).to receive(:respond_to?).with(:stat).and_return(false)
      end
      it 'returns the size of the file' do
        expect(subject.size).to eq(123)
      end
    end
    context 'when file responds to :stat' do
      before do
        allow(subject.file).to receive_message_chain(:stat, :size).and_return(456) # rubocop:disable RSpec/MessageChain
        allow(subject.file).to receive(:respond_to?).with(:size).and_return(false)
        allow(subject.file).to receive(:respond_to?).with(:stat).and_return(true)
      end
      it 'returns the size of the file' do
        expect(subject.size).to eq(456)
      end
    end
    context 'when file responds to neither :size nor :stat' do
      before do
        allow(subject.file).to receive(:respond_to?).with(:size).and_return(false)
        allow(subject.file).to receive(:respond_to?).with(:stat).and_return(false)
      end
      it 'returns nil' do
        expect(subject.size).to eq nil
      end
    end
  end
end
