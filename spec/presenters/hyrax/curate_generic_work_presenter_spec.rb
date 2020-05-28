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
      "depositor_tesim" => user_key,
      "holding_repository_tesim" => ["test holding repo"],
      "rights_statement_tesim" => ["empl.com"],
      "preservation_workflow_terms_tesim" => ["{\"workflow_type\":\"Ingest\",\"workflow_notes\":\"Migrated to Cor repository from Extensis Portfolio\",
        \"workflow_rights_basis\":\"Administrative Signo\",\"workflow_rights_basis_note\":\"This is a sample note. This field isn't always populated.\",
        \"workflow_rights_basis_date\":\"2016-03-01\",\"workflow_rights_basis_reviewer\":\"Scholarly Communications Office\",\"workflow_rights_basis_uri\":null}"] }
  end

  describe '#manifest_url' do
    context 'when request is not nil' do
      subject { presenter.manifest_url }
      let(:presenter) { described_class.new(solr_document, ability, request) }
      before do
        allow(request).to receive(:host).and_return 'example.org'
        allow(request).to receive(:base_url).and_return 'http://example.org'
      end

      it { is_expected.to eq 'http://example.org/iiif/888888/manifest' }
    end

    context 'when request is nil and HOSTNAME is nil' do
      subject { presenter.manifest_url }
      let(:presenter) { described_class.new(solr_document, ability) }
      before { ENV['HOSTNAME'] = nil }

      it { is_expected.to eq "http://localhost:3000/iiif/888888/manifest" }
    end

    context 'when request is nil and HOSTNAME is assigned' do
      subject { presenter.manifest_url }
      let(:presenter) { described_class.new(solr_document, ability) }
      before { ENV['HOSTNAME'] = 'example-curate' }

      it { is_expected.to eq "http://example-curate/iiif/888888/manifest" }
    end
  end

  describe "instance methods" do
    let(:presenter) { described_class.new(solr_document, ability) }

    before do
      ENV['LUX_BASE_URL'] = "https://example.com"
    end

    describe "#manifest_metadata" do
      subject { presenter.manifest_metadata }

      it {
        is_expected.to eq [{ "label" => "Provided by", "value" => ["test holding repo"] }, { "label" => "Rights Status", "value" => ["empl.com"] },
                           { "label" => "Identifier", "value" => "888888" },
                           { "label" => "Persistent URL", "value" => "<a href=\"https://example.com/purl/888888\">https://example.com/purl/888888</a>" }]
      }
    end

    describe "#purl" do
      subject { presenter.purl }
      it { is_expected.to eq "https://example.com/purl/888888" }
    end

    describe "#preservation_workflows" do
      subject :workflows do
        presenter.preservation_workflows
      end
      it "returns preservation workflows" do
        expect(workflows.any? { |pwf| pwf['workflow_type'] == 'Ingest' }).to be_truthy
        expect(workflows.any? { |pwf| pwf['workflow_type'] == 'Accession' }).to be_falsy
      end
    end
  end
end
