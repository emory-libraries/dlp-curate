# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work CurateGenericWork`
require 'rails_helper'

RSpec.describe Hyrax::CurateGenericWorkPresenter do
  let(:solr_document) { SolrDocument.new(attributes) }
  let(:request) { instance_double(ActionDispatch::Request) }
  let(:ability) { instance_double(Ability) }
  let(:user_key) { 'a_user_key' }
  let(:attributes) do
    { "id" => '888888',
      "title_tesim" => ['foo', 'bar'],
      "human_readable_type_tesim" => ["Curate Generic Work"],
      "has_model_ssim" => ["CurateGenericWork"],
      "date_created_tesim" => ['an unformatted date'],
      "depositor_tesim" => user_key }
  end

  describe '#manifest_url' do
    context 'when request is not nil' do
      subject { presenter.manifest_url }
      let(:presenter) { described_class.new(solr_document, ability, request) }
      before do
        allow(request).to receive(:host).and_return 'example.org'
        allow(request).to receive(:base_url).and_return 'http://example.org'
      end

      it { is_expected.to eq 'http://example.org/concern/curate_generic_works/888888/manifest' }
    end

    context 'when request is nil and HOSTNAME is nil' do
      subject { presenter.manifest_url }
      let(:presenter) { described_class.new(solr_document, ability) }
      before { ENV['HOSTNAME'] = nil }

      it { is_expected.to eq "http://localhost:3000/concern/curate_generic_works/888888/manifest" }
    end

    context 'when request is nil and HOSTNAME is assigned' do
      subject { presenter.manifest_url }
      let(:presenter) { described_class.new(solr_document, ability) }
      before { ENV['HOSTNAME'] = 'example-curate' }

      it { is_expected.to eq "http://example-curate/concern/curate_generic_works/888888/manifest" }
    end
  end
end
