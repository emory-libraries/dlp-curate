# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Curate::CustomQueries::FindByEmoryPersistentId do
  let(:connection) { instance_double(RSolr::Client) }
  let(:query_service) { instance_double('QueryService', find_by: resource) }
  let(:handler) { described_class.new(query_service:) }
  let(:resource) { double('Valkyrie::Resource', id: 'abc-123') }

  before do
    allow(Hyrax).to receive_message_chain(:index_adapter, :connection).and_return(connection)
  end

  describe '#find_by_emory_persistent_id' do
    context 'when a matching document exists in Solr' do
      before do
        allow(connection).to receive(:get).with(
          "select",
          params: { q: "emory_persistent_id_ssi:508hdr7srt-cor", fl: "*", rows: 1 }
        ).and_return("response" => { "docs" => [{ "id" => "abc-123" }] })
      end

      it 'returns the resource' do
        result = handler.find_by_emory_persistent_id(emory_persistent_id: '508hdr7srt-cor')
        expect(result).to eq resource
      end
    end

    context 'when no matching document exists' do
      before do
        allow(connection).to receive(:get).with(
          "select",
          params: { q: "emory_persistent_id_ssi:nonexistent-cor", fl: "*", rows: 1 }
        ).and_return("response" => { "docs" => [] })
      end

      it 'raises ObjectNotFoundError' do
        expect do
          handler.find_by_emory_persistent_id(emory_persistent_id: 'nonexistent-cor')
        end.to raise_error(Valkyrie::Persistence::ObjectNotFoundError)
      end
    end
  end
end
