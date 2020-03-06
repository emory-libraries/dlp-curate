# frozen_string_literal: true
require "rails_helper"
require 'cgi'

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
  let(:manifest_output) { File.read(fixture_path + '/manifest_json_output.json') }
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
  let(:original_checksum) do
    ['urn:md5:da674abf5cc0750158ebe9f8fdb83faf',
     'urn:sha1:fba6a26214287bb0c50ecb2e4922041dcb84b256',
     'urn:sha256:7399acb3f34ec4cb06a55b0ca79e637fee3552cc599d7cd2eb6b17e3a2db94e7']
  end

  before do
    Hydra::Works::AddFileToFileSet.call(file_set, pmf, :preservation_master_file)
    work.ordered_members << file_set
    work.save!
    allow_any_instance_of(FileSet).to receive(:original_checksum).and_return(original_checksum)
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
    doc = manifest_output
    expect(JSON.parse(rendered)).to eq(JSON.parse(doc))
  end
end
