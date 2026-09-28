# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Curate::ValkyrieObjectRemediationService do
  subject(:service) { described_class.new(logger:) }
  let(:logger) { instance_double(Logger, info: nil, error: nil) }

  describe '#migrate_alternate_ids_to_emory_persistent_id' do
    let(:persister) { instance_double('Persister') }
    let(:index_adapter) { instance_double('IndexAdapter') }

    before do
      allow(Hyrax).to receive(:persister).and_return(persister)
      allow(Hyrax).to receive(:index_adapter).and_return(index_adapter)
    end

    context 'when objects with alternate_ids exist' do
      let(:resource) do
        double(
          'Valkyrie::Resource',
          id:                     'abc-123',
          alternate_ids:          [Valkyrie::ID.new('508hdr7srt-cor')],
          emory_persistent_id:    nil,
          'emory_persistent_id=': nil,
          'alternate_ids=':       nil
        )
      end
      let(:saved_resource) { resource }

      before do
        allow(resource).to receive(:respond_to?).with(:emory_persistent_id).and_return(true)
        allow(Hyrax.query_service).to receive_message_chain(:custom_queries, :find_all_objects_with_alternate_ids_present).and_return([resource])
        allow(persister).to receive(:save).and_return(saved_resource)
        allow(index_adapter).to receive(:save)
      end

      it 'migrates alternate_ids to emory_persistent_id' do
        result = service.migrate_alternate_ids_to_emory_persistent_id

        expect(resource).to have_received(:emory_persistent_id=).with('508hdr7srt-cor')
        expect(resource).to have_received(:alternate_ids=).with([])
        expect(persister).to have_received(:save).with(resource:)
        expect(index_adapter).to have_received(:save).with(resource: saved_resource)
        expect(result[:migrated]).to eq 1
        expect(result[:errored]).to eq 0
      end
    end

    context 'when emory_persistent_id is already set' do
      let(:resource) do
        double(
          'Valkyrie::Resource',
          id:                  'abc-123',
          alternate_ids:       [Valkyrie::ID.new('508hdr7srt-cor')],
          emory_persistent_id: 'existing-cor'
        )
      end

      before do
        allow(resource).to receive(:respond_to?).with(:emory_persistent_id).and_return(true)
        allow(Hyrax.query_service).to receive_message_chain(:custom_queries, :find_all_objects_with_alternate_ids_present).and_return([resource])
      end

      it 'skips the resource and reports it' do
        result = service.migrate_alternate_ids_to_emory_persistent_id

        expect(result[:migrated]).to eq 0
        expect(result[:skipped]).to eq 1
        expect(result[:errored]).to eq 0
        expect(logger).to have_received(:info).with(/already set/)
      end
    end

    context 'when no objects have alternate_ids' do
      before do
        allow(Hyrax.query_service).to receive_message_chain(:custom_queries, :find_all_objects_with_alternate_ids_present).and_return([])
      end

      it 'reports zero migrations' do
        result = service.migrate_alternate_ids_to_emory_persistent_id

        expect(result[:migrated]).to eq 0
        expect(result[:errored]).to eq 0
      end
    end
  end
end
