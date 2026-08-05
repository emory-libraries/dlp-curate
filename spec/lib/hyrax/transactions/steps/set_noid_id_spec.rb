# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hyrax::Transactions::Steps::SetNoidId do
  subject(:step) { described_class.new }
  let(:noid_service) { instance_double(Noid::Rails::Service, mint: '508hdr7srt') }

  before do
    allow(Noid::Rails::Service).to receive(:new).and_return(noid_service)
    allow(Rails.configuration.x).to receive(:curate_template).and_return('-cor')
  end

  describe '#call' do
    context 'when the change_set supports emory_persistent_id' do
      let(:change_set) do
        instance_double(
          'Hyrax::ChangeSet',
          emory_persistent_id: nil,
          'emory_persistent_id=': nil,
          id: Valkyrie::ID.new('abc123')
        )
      end

      before do
        allow(change_set).to receive(:respond_to?).with(:emory_persistent_id=).and_return(true)
        allow(change_set).to receive(:respond_to?).with(:emory_persistent_id).and_return(true)
        allow(Hyrax).to receive_message_chain(:persister, :save).and_return(change_set)
      end

      it 'mints a NOID and sets emory_persistent_id' do
        result = step.call(change_set)

        expect(result).to be_success
        expect(change_set).to have_received(:emory_persistent_id=).with('508hdr7srt-cor')
      end

      it 'saves the resource' do
        step.call(change_set)

        expect(Hyrax.persister).to have_received(:save).with(resource: change_set)
      end
    end

    context 'when emory_persistent_id is already set' do
      let(:change_set) do
        instance_double(
          'Hyrax::ChangeSet',
          emory_persistent_id: '999abc123-cor',
          id: Valkyrie::ID.new('abc123')
        )
      end

      before do
        allow(change_set).to receive(:respond_to?).with(:emory_persistent_id=).and_return(true)
        allow(change_set).to receive(:respond_to?).with(:emory_persistent_id).and_return(true)
      end

      it 'does not mint a new NOID' do
        result = step.call(change_set)

        expect(result).to be_success
        expect(noid_service).not_to have_received(:mint)
      end
    end

    context 'when the change_set does not support emory_persistent_id' do
      let(:change_set) { instance_double('Hyrax::ChangeSet') }

      before do
        allow(change_set).to receive(:respond_to?).with(:emory_persistent_id=).and_return(false)
      end

      it 'returns a failure' do
        result = step.call(change_set)

        expect(result).to be_failure
      end
    end
  end
end
