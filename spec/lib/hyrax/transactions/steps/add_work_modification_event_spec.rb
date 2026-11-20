# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('lib', 'hyrax', 'transactions', 'steps', 'add_work_modification_event')

RSpec.describe Hyrax::Transactions::Steps::AddWorkModificationEvent do
  subject(:step) { described_class.new }
  let(:work) { CurateGenericWorkResource.new(title: ['A work']) }
  let(:change_set) { double('Hyrax::ChangeSet', model: work) }
  let(:event_attributes) do
    work.preservation_event.map do |e|
      { type: Array(e.event_type).first, details: Array(e.event_details).first, user: Array(e.initiating_user).first,
        outcome: Array(e.outcome).first, software: Array(e.software_version).first }
    end
  end

  before do
    allow(Hyrax.persister).to receive(:save) { |resource:| resource }
  end

  describe '#call' do
    it 'attaches a Modification event for the editing user to the unsaved work' do
      expect(step.call(change_set, initiating_user: 'editor-uid')).to be_success
      expect(event_attributes).to contain_exactly(
        { type: 'Modification', details: 'Object updated', user: 'editor-uid', outcome: 'Success', software: 'Curate v.1' }
      )
    end

    it 'persists the event but not the work' do
      step.call(change_set, initiating_user: 'editor-uid')

      expect(Hyrax.persister).to have_received(:save).with(resource: an_instance_of(PreservationEventResource)).once
      expect(Hyrax.persister).not_to have_received(:save).with(resource: work)
    end

    it 'keeps the events the work already has' do
      work.preservation_event = [PreservationEventResource.new(event_type: 'Validation')]

      step.call(change_set, initiating_user: 'editor-uid')

      expect(event_attributes.map { |e| e[:type] }).to eq ['Validation', 'Modification']
    end

    context 'without an editing user' do
      it 'adds no event, as when the import attaches FileSets or a work is migrated' do
        expect(step.call(change_set)).to be_success
        expect(work.preservation_event).to be_empty
        expect(Hyrax.persister).not_to have_received(:save)
      end
    end

    context 'when the model has no preservation events' do
      let(:work) { Hyrax::Work.new }

      it 'succeeds without creating an event' do
        expect(step.call(change_set, initiating_user: 'editor-uid')).to be_success
        expect(Hyrax.persister).not_to have_received(:save)
      end
    end

    context 'when the event cannot be persisted' do
      before { allow(Hyrax.persister).to receive(:save).and_raise(StandardError, 'Fedora unavailable') }

      it 'fails the transaction' do
        result = step.call(change_set, initiating_user: 'editor-uid')

        expect(result).to be_failure
        expect(result.failure.first).to include('Fedora unavailable')
      end
    end
  end
end
