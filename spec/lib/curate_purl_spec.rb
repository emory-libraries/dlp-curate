# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CuratePurl do
  let(:test_class) do
    Class.new do
      include CuratePurl
      attr_accessor :id, :emory_persistent_id, :solr_document

      def initialize(id:, emory_persistent_id: nil, solr_document: nil)
        @id = id
        @emory_persistent_id = emory_persistent_id
        @solr_document = solr_document
      end
    end
  end

  before { ENV['LUX_BASE_URL'] = 'https://example.com' }
  after  { ENV.delete('LUX_BASE_URL') }

  describe '#purl' do
    context 'when emory_persistent_id is present' do
      subject { test_class.new(id: 'uuid-123', emory_persistent_id: '508hdr7srt-cor').purl }

      it { is_expected.to eq 'https://example.com/purl/508hdr7srt-cor' }
    end

    context 'when emory_persistent_id is blank but solr_document has it' do
      let(:solr_doc) { { 'emory_persistent_id_ssi' => '999abc123-cor' } }
      subject { test_class.new(id: 'uuid-123', solr_document: solr_doc).purl }

      it { is_expected.to eq 'https://example.com/purl/999abc123-cor' }
    end

    context 'when neither emory_persistent_id nor solr_document are available' do
      subject { test_class.new(id: '888888').purl }

      it { is_expected.to eq 'https://example.com/purl/888888' }
    end

    context 'when LUX_BASE_URL is not set' do
      before { ENV.delete('LUX_BASE_URL') }
      subject { test_class.new(id: '888888').purl }

      it { is_expected.to eq 'localhost:3000/purl/888888' }
    end
  end
end
