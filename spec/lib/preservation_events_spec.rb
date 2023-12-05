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
