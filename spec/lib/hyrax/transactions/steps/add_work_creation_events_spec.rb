# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('lib', 'hyrax', 'transactions', 'steps', 'add_work_creation_events')

RSpec.describe Hyrax::Transactions::Steps::AddWorkCreationEvents do
  subject(:step) { described_class.new }
  let(:work) { CurateGenericWorkResource.new(title: ['A work']) }
  let(:change_set) { double('Hyrax::ChangeSet', model: work, depositor: 'depositor-uid', visibility: 'open') }
  let(:event_attributes) do
    work.preservation_event.map do |e|
      { type: Array(e.event_type).first, details: Array(e.event_details).first, user: Array(e.initiating_user).first, outcome: Array(e.outcome).first }
    end
  end

  before do
    allow(Hyrax.persister).to receive(:save) { |resource:| resource }
  end

  describe '#call' do
    it 'attaches the Validation and Policy Assignment events to the unsaved work' do
      expect(step.call(change_set, initiating_user: 'importer@emory.edu')).to be_success
      expect(event_attributes).to contain_exactly(
        { type: 'Validation', details: 'Submission package validated', user: 'importer@emory.edu', outcome: 'Success' },
        { type: 'Policy Assignment', details: 'Visibility/access controls assigned: open', user: 'importer@emory.edu', outcome: 'Success' }
      )
    end

    it 'persists the events but not the work' do
      step.call(change_set)

      expect(Hyrax.persister).to have_received(:save).with(resource: an_instance_of(PreservationEventResource)).twice
      expect(Hyrax.persister).not_to have_received(:save).with(resource: work)
    end

    it 'records the depositor when no initiating user is given' do
      step.call(change_set)

      expect(event_attributes.map { |e| e[:user] }).to all(eq 'depositor-uid')
    end

    context 'when the model has no preservation events' do
      let(:work) { Hyrax::Work.new }

      it 'succeeds without creating events' do
        expect(step.call(change_set)).to be_success
        expect(Hyrax.persister).not_to have_received(:save)
      end
    end

    context 'when an event cannot be persisted' do
      before { allow(Hyrax.persister).to receive(:save).and_raise(StandardError, 'Fedora unavailable') }

      it 'fails the transaction' do
        result = step.call(change_set)

        expect(result).to be_failure
        expect(result.failure.first).to include('Fedora unavailable')
      end
    end
  end
end
