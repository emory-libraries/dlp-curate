require 'rails_helper'
require 'redlock'

RSpec.describe Hyrax::Actors::FileSetActor do
  include ActionDispatch::TestProcess

  let(:user)          { FactoryBot.create(:user) }
  let(:file_path)     { File.join(fixture_path, 'sun.png') }
  let(:file)          { fixture_file_upload(file_path, 'image/png') } # we will override for the different types of File objects
  let(:local_file)    { File.open(file_path) }
  let(:file_set)      { FactoryBot.build(:file_set, content: local_file) }
  let(:actor)         { described_class.new(file_set, user) }
  let(:relation)      { :original_file }
  let(:file_actor)    { Hyrax::Actors::FileActor.new(file_set, relation, user) }

  describe '#create_content' do
    before do
      expect(JobIoWrapper).to receive(:create_with_varied_file_handling!).with(any_args).and_return(JobIoWrapper.new)
      expect(IngestJob).to receive(:perform_later).with(JobIoWrapper)
    end

    context 'when file_set.title is empty and file_set.label is not' do
      let(:long_name) do
        'an absurdly long title that goes on way to long and messes up the display of the page which should not need ' \
          'to be this big in order to show this impossibly long, long, long, oh so long string'
      end
      let(:short_name) { 'Short Example' }

      before do
        allow(file_set).to receive(:label).and_return(short_name)
        actor.create_content(file)
      end

      it "retains the object's short name" do
        expect(file_set.title).to include(short_name)
      end
    end

    context 'when a label is already specified' do
      let(:label) { 'test_file.png' }
      let(:file_set) do
        FileSet.new do |f|
          f.apply_depositor_metadata(user.user_key)
          f.label = label
        end
      end
      let(:actor) { described_class.new(file_set, user) }

      before do
        actor.create_content(file)
      end

      it "retains the object's original label" do
        expect(file_set.label).to eql(label)
      end
    end

    context 'when a fileset is saved' do
      before do
        actor.create_content(file)
      end

      it 'adds a new preservation_event for fileset creation' do
        expect(file_set.preservation_event.first.event_type).to eq ['Replication (FileSet created)']
        expect(file_set.preservation_event.first.outcome).to eq ['Success']
        expect(file_set.preservation_event.first.initiating_user).to eq [user.uid]
        expect(file_set.preservation_event.count).to eq 1
      end
    end
  end
end
