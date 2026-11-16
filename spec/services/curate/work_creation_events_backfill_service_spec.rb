# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Curate::WorkCreationEventsBackfillService do
  subject(:service) { described_class.new(logger:, dry_run:) }
  let(:logger) { instance_double(Logger, info: nil, error: nil) }
  let(:dry_run) { false }
  let(:fedora_query_service) { double('Valkyrie::Persistence::Fedora::QueryService') }
  let(:uploaded) { DateTime.new(2026, 10, 1, 15, 0, 0) }
  let(:valkyrie_work) do
    CurateGenericWorkResource.new(id: 'valkyrie-work', title: ['Valkyrie work'], depositor: 'dev-admin', date_uploaded: uploaded)
  end
  let(:event_types) { ->(work) { work.preservation_event.map { |e| Array(e.event_type).first } } }

  before do
    allow(Hyrax::SolrService).to receive(:query).and_return([{ 'id' => 'valkyrie-work' }, { 'id' => 'af-work' }])
    allow(Valkyrie::MetadataAdapter).to receive(:find).and_call_original
    allow(Valkyrie::MetadataAdapter).to receive(:find).with(:fedora_metadata)
                                                      .and_return(double('Valkyrie::Persistence::Fedora::MetadataAdapter', query_service: fedora_query_service))
    allow(fedora_query_service).to receive(:find_by).with(id: 'valkyrie-work').and_return(valkyrie_work)
    allow(fedora_query_service).to receive(:find_by).with(id: 'af-work').and_raise(Valkyrie::Persistence::ObjectNotFoundError)
    allow(Hyrax.query_service).to receive(:find_by).with(id: 'valkyrie-work').and_return(valkyrie_work)
    allow(Hyrax.persister).to receive(:save) { |resource:| resource }
    allow(Hyrax.index_adapter).to receive(:save)
  end

  describe '#backfill' do
    it 'adds both creation events to Valkyrie works without them and skips AF works' do
      expect(service.backfill).to eq(backfilled: 1, skipped: 1, errored: 0)
      expect(event_types.call(valkyrie_work)).to contain_exactly('Validation', 'Policy Assignment')
      expect(valkyrie_work.preservation_event.map { |e| Array(e.event_start).first }).to all(eq uploaded)
      expect(Hyrax.index_adapter).to have_received(:save).with(resource: valkyrie_work)
    end

    context 'when the work already has one creation event' do
      before do
        valkyrie_work.preservation_event = [PreservationEventResource.new(event_type: 'Validation', event_start: uploaded)]
      end

      it 'adds only the missing event' do
        service.backfill

        expect(event_types.call(valkyrie_work)).to contain_exactly('Validation', 'Policy Assignment')
      end
    end

    context 'when the work already has both creation events' do
      before do
        valkyrie_work.preservation_event = [PreservationEventResource.new(event_type: 'Validation'),
                                            PreservationEventResource.new(event_type: 'Policy Assignment')]
      end

      it 'skips it' do
        expect(service.backfill).to eq(backfilled: 0, skipped: 2, errored: 0)
        expect(Hyrax.persister).not_to have_received(:save)
      end
    end

    context 'with a dry run' do
      let(:dry_run) { true }

      it 'reports the work without changing it' do
        expect(service.backfill).to eq(backfilled: 1, skipped: 1, errored: 0)
        expect(valkyrie_work.preservation_event).to be_empty
        expect(Hyrax.persister).not_to have_received(:save)
      end
    end

    context 'when saving a work fails' do
      before { allow(Hyrax.persister).to receive(:save).and_raise(StandardError, 'Fedora unavailable') }

      it 'counts the error and continues' do
        expect(service.backfill).to eq(backfilled: 0, skipped: 1, errored: 1)
        expect(logger).to have_received(:error).with(/valkyrie-work: Fedora unavailable/)
      end
    end
  end
end
