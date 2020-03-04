# frozen_string_literal: true
require 'rails_helper'

RSpec.describe ManifestBuilderService, :clean do
  let(:identifier) { '508hdr7srq-cor' }
  let(:service) { described_class.new(presenter: presenter, curation_concern: work) }
  let(:ability) { instance_double(Ability) }
  let(:request) { instance_double(ActionDispatch::Request, base_url: 'example.com') }
  let(:presenter) { Hyrax::CurateGenericWorkPresenter.new(solr_document, ability, request) }
  let(:user) { FactoryBot.create(:user) }
  let(:work) { FactoryBot.create(:public_generic_work, id: identifier) }
  let(:solr_document) { SolrDocument.new(attributes) }
  let(:cache_file) { Rails.root.join('tmp', "2019-11-11_18-20-32_#{identifier}") }
  let(:attributes) do
    { "id" => identifier,
      "title_tesim" => [work.title.first],
      "human_readable_type_tesim" => ["Curate Generic Work"],
      "has_model_ssim" => ["CurateGenericWork"],
      "date_created_tesim" => ['an unformatted date'],
      "date_modified_dtsi" => "2019-11-11T18:20:32Z",
      "depositor_tesim" => user.uid,
      "holding_repository_tesim" => ["test holding repo"],
      "rights_statement_tesim" => ["example.com"] }
  end
  let(:file_set) { FactoryBot.create(:file_set) }
  let(:pmf) { File.open(fixture_path + '/book_page/0003_preservation_master.tif') }
  let(:sf) { File.open(fixture_path + '/book_page/0003_service.jpg') }

  before do
    ENV['IIIF_MANIFEST_CACHE'] = "./tmp"
    allow(SolrDocument).to receive(:find).and_return(solr_document)
    File.delete(cache_file) if File.exist?(cache_file)
  end

  after do
    File.delete(cache_file) if File.exist?(cache_file)
  end

  context "returning a iiif manifest" do
    it 'generates a iiif presentation manifest' do
      response_values = JSON.parse(service.manifest)
      expect(response_values["@context"]).to include "http://iiif.io/api/presentation/2/context.json"
    end

    it 'can be called at the class level' do
      response_values = JSON.parse(described_class.build_manifest(presenter: presenter, curation_concern: work))
      expect(response_values["@context"]).to include "http://iiif.io/api/presentation/2/context.json"
    end
  end

  describe "instance and class methods" do
    before do
      Hydra::Works::AddFileToFileSet.call(file_set, pmf, :preservation_master_file)
      Hydra::Works::AddFileToFileSet.call(file_set, sf, :service_file)
      work.ordered_members << file_set
      work.save!
    end

    after do
      work.ordered_members = []
      work.save!
    end

    context "#build_manifest class method" do
      it "saves manifest file" do
        expect(File).not_to exist(cache_file)
        response_values = JSON.parse(described_class.build_manifest(presenter: presenter, curation_concern: work))
        expect(response_values).to_s.match(identifier)
        expect(File).to exist(cache_file)

        response_values = JSON.parse(File.open(cache_file).read)

        expect(response_values).to include "@context"
        expect(response_values["@context"]).to include "http://iiif.io/api/presentation/2/context.json"
        expect(response_values).to include "@type"
        expect(response_values["@type"]).to include "sc:Manifest"
        expect(response_values).to include "@id"
        expect(response_values["@id"]).to include "/iiif/#{work.id}/manifest"
        expect(response_values).to include "label"
        expect(response_values["label"]).to include work.title.first.to_s
        expect(response_values).to include "metadata"
        expect(response_values["metadata"][0]["label"]).to eq "Provided by"
        expect(response_values["metadata"][0]["value"]).to eq ["test holding repo"]
        expect(response_values["metadata"][1]["label"]).to eq "Rights Status"
        expect(response_values["metadata"][1]["value"]).to eq ["example.com"]
        expect(response_values["metadata"][2]["label"]).to eq "Identifier"
        expect(response_values["metadata"][2]["value"]).to eq work.id
        expect(response_values).to include "sequences"
        expect(response_values["sequences"].first["@type"]).to include "sc:Sequence"
        expect(response_values["sequences"].first["@id"]).to include "/iiif/#{work.id}/manifest/sequence/normal"
        expect(response_values["sequences"].first["canvases"].first["@id"]).to include "/iiif/#{work.id}/manifest/canvas/#{file_set.id}"
        expect(response_values["sequences"].first["canvases"].first["images"].first["resource"]["@id"]).to include(
          "/images/#{file_set.id}%2Ffiles%2F#{file_set.service_file.id.split('/').last}/full/600,/0/default.jpg"
        )
      end
    end

    context "#iiif_url and #info_url instance methods" do
      let(:service) { described_class.new(curation_concern: file_set) }

      context "for localhost" do
        it "returns appropriate iiif_url and info_url" do
          expect(service.iiif_url).to include "/images/#{file_set.id}%2Ffiles%2F#{file_set.service_file.id.split('/').last}/full/600,/0/default.jpg"
          expect(service.info_url).to include "/images/#{file_set.id}%2Ffiles%2F#{file_set.service_file.id.split('/').last}"
        end
      end

      context "for iiif_server" do
        before do
          ENV['IIIF_SERVER_URL'] = 'example.com/iiif/2/'
          ENV['FEDORA_ADAPTER'] = 's3'
        end

        after do
          ENV['IIIF_SERVER_URL'] = nil
          ENV['FEDORA_ADAPTER'] = nil
        end

        it "returns appropriate iiif_url" do
          expect(service.iiif_url).to include "example.com/iiif/2/"
          expect(service.info_url).to include "example.com/iiif/2/"
        end
      end
    end
  end
end
