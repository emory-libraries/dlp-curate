# frozen_string_literal: true
require 'rails_helper'
require_relative '../../fixtures/manifest_output.rb'

RSpec.describe "manifest/manifest", type: :view, clean: true do
  let(:identifier)      { '508hdr7srq-cor' }
  let(:work)            { FactoryBot.create(:public_generic_work, id: identifier) }
  let(:builder_service) { ManifestBuilderService.new(curation_concern: work) }
  let(:image_concerns)  { ManifestPersistenceJob.new.send(:image_concerns, work) }
  let(:root_url)        { presenter.manifest_url }
  let(:renderings)      { rendering_output }
  let(:ability)         { instance_double(Ability) }
  let(:request)         { instance_double(ActionDispatch::Request, base_url: 'example.com') }
  let(:presenter)       { Hyrax::CurateGenericWorkPresenter.new(solr_document, ability, request) }
  let(:solr_document)   { SolrDocument.new(attributes) }
  let(:file_set)        { FactoryBot.create(:file_set, id: '608hdr7qrt-cor', title: ['foo'], read_groups: ['public']) }
  let(:file_set1)       { FactoryBot.create(:file_set, id: '608hdr7srt-cor', title: ['foo1'], read_groups: ['public']) }
  let(:file_set2)       { FactoryBot.create(:file_set, id: '608hdr7rrt-cor', title: ['foo2'], read_groups: ['public']) }
  let(:file_set3)       { FactoryBot.create(:file_set, id: '608hdr7jrt-cor', title: ['foo3'], read_groups: ['public']) }
  let(:private_fs)      { FactoryBot.create(:file_set, id: '608hdr7trt-cor') }
  let(:pmf)             { File.open(fixture_path + '/book_page/0003_preservation_master.tif') }
  let(:sf)              { File.open(fixture_path + '/book_page/0003_service.jpg') }
  let(:imf)             { File.open(fixture_path + '/book_page/0003_intermediate.jp2') }
  let(:pdf)             { File.open(fixture_path + '/sample-file.pdf') }
  let(:ocr)             { File.open(fixture_path + '/sample-ocr.xml') }
  let(:txt)             { File.open(fixture_path + '/sample-text.txt') }
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
      "rights_statement_tesim" => ["example.com"],
      "hasFormat_ssim" => ["608hdr7srt-cor", "608hdr7rrt-cor", "608hdr7jrt-cor"] }
  end

  let(:rendering_output) do
    [
      {
        "@id" => "http://localhost:3000/downloads/#{file_set1.id}",
        "format" => file_set1.mime_type,
        "label" => "Download whole resource: #{file_set1.title.first}"
      },
      {
        "@id" => "http://localhost:3000/downloads/#{file_set2.id}",
        "format" => file_set2.mime_type,
        "label" => "Download whole resource: #{file_set2.title.first}"
      },
      {
        "@id" => "http://localhost:3000/downloads/#{file_set3.id}",
        "format" => file_set3.mime_type,
        "label" => "Download whole resource: #{file_set3.title.first}"
      }
    ]
  end

  before do
    Hydra::Works::AddFileToFileSet.call(file_set, pmf, :preservation_master_file)
    Hydra::Works::AddFileToFileSet.call(file_set, sf, :service_file)
    Hydra::Works::AddFileToFileSet.call(file_set, imf, :intermediate_file)
    Hydra::Works::AddFileToFileSet.call(file_set1, pdf, :preservation_master_file)
    Hydra::Works::AddFileToFileSet.call(file_set2, ocr, :preservation_master_file)
    Hydra::Works::AddFileToFileSet.call(file_set3, txt, :preservation_master_file)
    Hydra::Works::AddFileToFileSet.call(private_fs, pmf, :preservation_master_file)
    work.ordered_members << file_set
    work.ordered_members << file_set1
    work.ordered_members << file_set2
    work.ordered_members << file_set3
    # Adding the private file_set to the work without changing the rendered output.
    # This will make sure the file_set is a member of the work but is not added to
    # the manifest.
    work.ordered_members << private_fs
    work.save!
    assign(:solr_doc, solr_document)
    assign(:image_concerns, image_concerns)
    assign(:root_url, root_url)
    assign(:manifest_rendering, renderings)
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
    expect(work.file_sets.count).to eq 5
  end

  describe 'IIIF Search' do
    context "FileSet's alto_xml_tesi and Work's all_text_timv are present" do
      let(:solr_document) { SolrDocument.new(attributes.merge("all_text_tsimv": 'text, yada yada')) }

      it 'renders a IIIF Search service' do
        allow(image_concerns).to receive(:any?).and_return(true)
        render
        parsed_rendered_manifest = JSON.parse(rendered)

        expect(parsed_rendered_manifest['service']).to be_present
        expect(parsed_rendered_manifest['service'].first['@context']).to eq('http://iiif.io/api/search/0/context.json')
        expect(parsed_rendered_manifest['service'].first['profile']).to eq('http://iiif.io/api/search/0/search')
        expect(parsed_rendered_manifest['service'].first['@id']).to eq("/catalog/#{identifier}/iiif_search")
      end
    end

    context "FileSet's alto_xml_tesi is present" do
      it 'does not render the IIIF Search service' do
        allow(image_concerns).to receive(:any?).and_return(true)
        render
        parsed_rendered_manifest = JSON.parse(rendered)

        expect(parsed_rendered_manifest['service']).not_to be_present
      end
    end

    context "Work's all_text_timv is present" do
      let(:solr_document) { SolrDocument.new(attributes.merge("all_text_tsimv": 'text, yada yada')) }

      it 'does not render the IIIF Search service' do
        render
        parsed_rendered_manifest = JSON.parse(rendered)

        expect(parsed_rendered_manifest['service']).not_to be_present
      end
    end
  end
end
