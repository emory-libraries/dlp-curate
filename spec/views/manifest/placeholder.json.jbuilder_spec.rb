# frozen_string_literal: true
require 'rails_helper'
require_relative '../../fixtures/placeholder_manifest_output.rb'

RSpec.describe "manifest/placeholder", type: :view, clean: true do
  let(:identifier)      { '508hdr7srq-cor' }
  let(:work)            { FactoryBot.create(:public_generic_work, id: identifier) }
  let(:manifest)        { PlaceholderManifestOutput.new }
  let(:root_url)        { presenter.manifest_url }
  let(:ability)         { instance_double(Ability) }
  let(:request)         { instance_double(ActionDispatch::Request, base_url: 'example.com') }
  let(:presenter)       { Hyrax::CurateGenericWorkPresenter.new(solr_document, ability, request) }
  let(:solr_document)   { SolrDocument.new(attributes) }
  let(:attributes) do
    { "id" => identifier,
      "title_tesim" => [work.title.first] }
  end

  before do
    assign(:root_url, root_url)
  end

  around do |example|
    ENV['IIIF_SERVER_URL'] = 'example.com/iiif/2/'
    ENV['FEDORA_ADAPTER'] = 's3'
    example.run
    ENV['IIIF_SERVER_URL'] = nil
    ENV['FEDORA_ADAPTER'] = nil
  end

  it 'displays placeholder manifest with text' do
    render
    doc = manifest.manifest_output(work).to_json
    expect(JSON.parse(rendered)).to eq(JSON.parse(doc))
  end
end
