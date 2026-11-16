# frozen_string_literal: true
require "rails_helper"
include PreservationEvents

RSpec.describe PreservationEvents, :clean do
  let(:file_set) { FactoryBot.create(:file_set) }
  let(:sha1) { '267d6c28761a0c95680bde0797f73c0837b2c8cz' }
  let(:start) { 'Wed, 08 Mar 2023 14:45:16 +0000' }
  let(:event) do
    { 'type' => 'Fixity Check', 'start' => start, 'end' => 'Wed, 08 Mar 2023 16:45:16 +0000',
      'details' => "Fixity intact for sha1:#{sha1} in aws_bucket",
      'software_version' => 'Fedora v4.7.6', 'user' => 'bobsuruncle', 'outcome' => 'Success' }
  end

  before { create_preservation_event(file_set, event) }

  context '#append_preservation_event_to_current' do
    let(:intermediate_id) { Valkyrie::ID.new('fm-intermediate') }
    let(:current_file_set) { FileSetResource.new(id: Valkyrie::ID.new('fs-1'), file_ids: [intermediate_id]) }
    let(:preservation_event) { PreservationEventResource.new(id: Valkyrie::ID.new('pe-1')) }

    before do
      allow(Hyrax.query_service).to receive(:find_by).with(id: current_file_set.id).and_return(current_file_set)
      allow(Hyrax.persister).to receive(:save).and_call_original
      allow(Hyrax.persister).to receive(:save).with(resource: kind_of(PreservationEventResource)).and_return(preservation_event)
      allow(Hyrax.persister).to receive(:save).with(resource: current_file_set) { |resource:| resource }
    end

    it 'adds the event to the currently persisted FileSet, keeping files attached meanwhile' do
      saved = append_preservation_event_to_current(current_file_set.id, event)

      expect(saved.preservation_event).to eq [preservation_event]
      expect(saved.file_ids).to eq [intermediate_id]
    end
  end

  context '#check_for_preexisting_preservation_events' do
    it 'finds a matching event' do
      expect(
        check_for_preexisting_preservation_events(file_set, sha1, start)
      ).to be_truthy
    end

    describe 'info that does not match' do
      it 'finds nothing with wrong sha1' do
        expect(
          check_for_preexisting_preservation_events(file_set, '267d6c28761a0c95680bde0797f73c0837b2c8cd', start)
        ).to be_falsey
      end

      it 'finds nothing with wrong start' do
        expect(
          check_for_preexisting_preservation_events(file_set, sha1, 'Wed, 09 Mar 2023 14:45:16 +0000')
        ).to be_falsey
      end
    end
  end
end
