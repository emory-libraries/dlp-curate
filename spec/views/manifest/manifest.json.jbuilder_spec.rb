# frozen_string_literal: true
require 'rails_helper'
require_relative '../../fixtures/manifest_output.rb'

RSpec.describe "manifest/manifest", type: :view do
  let(:identifier)      { '508hdr7srq-cor' }
  let(:work)            { FactoryBot.create(:public_generic_work, id: identifier) }
  let(:builder_service) { ManifestBuilderService.new(curation_concern: work) }
  let(:image_concerns)  { builder_service.send(:image_concerns) }
  let(:root_url)        { presenter.manifest_url }
  let(:ability)         { instance_double(Ability) }
  let(:request)         { instance_double(ActionDispatch::Request, base_url: 'example.com') }
  let(:presenter)       { Hyrax::CurateGenericWorkPresenter.new(solr_document, ability, request) }
  let(:solr_document)   { SolrDocument.new(attributes) }
  let(:file_set)        { FactoryBot.create(:file_set, id: '608hdr7qrt-cor', title: ['foo']) }
  let(:pmf)             { File.open(fixture_path + '/book_page/0003_preservation_master.tif') }
  let(:sf)              { File.open(fixture_path + '/book_page/0003_service.jpg') }
  let(:imf)             { File.open(fixture_path + '/book_page/0003_intermediate.jp2') }
  let(:manifest)        { ManifestOutput.new }
  let(:attributes) do
    { "id" => identifier,
      "title_tesim" => [work.title.first],
      "human_readable_type_tesim" => ["Curate Generic Work"],
      "has_model_ssim" => ["CurateGenericWork"],
      "date_created_tesim" => ['an unformatted date'],
      "date_modified_dtsi" => "2019-11-11T18:20:32Z",
      "depositor_tesim" => 'example_user',
      "holding_repository_tesim" => ["test holding repo"],
      "rights_statement_tesim" => ["example.com"] }
  end

  before do
    Hydra::Works::AddFileToFileSet.call(file_set, pmf, :preservation_master_file)
    Hydra::Works::AddFileToFileSet.call(file_set, sf, :service_file)
    Hydra::Works::AddFileToFileSet.call(file_set, imf, :intermediate_file)
    work.ordered_members << file_set
    work.save!
    assign(:solr_doc, solr_document)
    assign(:image_concerns, image_concerns)
    assign(:root_url, root_url)
  end

  around do |example|
    ENV['IIIF_SERVER_URL'] = 'example.com/iiif/2/'
    ENV['FEDORA_ADAPTER'] = 's3'
    example.run
    ENV['IIIF_SERVER_URL'] = nil
    ENV['FEDORA_ADAPTER'] = nil
  end

  it "displays a valid IIIF Presentation API manifest" do
    render
    doc = manifest.manifest_output(work, file_set).to_json
    expect(JSON.parse(rendered)).to eq(JSON.parse(doc))
  end
end
