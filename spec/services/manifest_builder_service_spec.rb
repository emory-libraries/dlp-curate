# frozen_string_literal: true
require 'rails_helper'

RSpec.describe ManifestBuilderService, :clean, perform_enqueued: [ManifestPersistenceJob] do
  let(:identifier) { '508hdr7srq-cor' }
  let(:service) { described_class.new(presenter: presenter, curation_concern: work) }
  let(:ability) { instance_double(Ability) }
  let(:request) { instance_double(ActionDispatch::Request, base_url: 'example.com') }
  let(:presenter) { Hyrax::CurateGenericWorkPresenter.new(solr_document, ability, request) }
  let(:user) { FactoryBot.create(:user) }
  let(:work) { FactoryBot.create(:public_generic_work, id: identifier) }
  let(:solr_document) { SolrDocument.new(attributes) }
  let(:cache_file) { Rails.root.join('tmp', "d28c5b20cf9b9663181d02b5ce90fac59fa666d7_#{identifier}") }
  let(:attributes) do
    { "id" => identifier,
      "title_tesim" => [work.title.first],
      "human_readable_type_tesim" => ["Curate Generic Work"],
      "has_model_ssim" => ["CurateGenericWork"],
      "date_created_tesim" => ['an unformatted date'],
      "date_modified_dtsi" => "2019-11-11T18:20:32Z",
      "depositor_tesim" => user.uid,
      "holding_repository_tesim" => ["test holding repo"],
      "rights_statement_tesim" => "http://rightsstatements.org/vocab/InC/1.0/",
      "hasFormat_ssim" => ["608hdr7srt-cor"],
      "manifest_cache_key_tesim" => ["d28c5b20cf9b9663181d02b5ce90fac59fa666d7"] }
  end
  let(:file_set)  { FactoryBot.create(:file_set, read_groups: ['public']) }
  let(:file_set2) { FactoryBot.create(:file_set, read_groups: ['public']) }
  let(:file_set3) { FactoryBot.create(:file_set, id: '608hdr7srt-cor', read_groups: ['public']) }
  let(:pmf) { File.open(fixture_path + '/book_page/0003_preservation_master.tif') }
  let(:sf) { File.open(fixture_path + '/book_page/0003_service.jpg') }
  let(:pdf) { File.open(fixture_path + '/sample-file.pdf') }

  before do
    allow(SolrDocument).to receive(:find).and_return(solr_document)
  end

  around do |example|
    File.delete(cache_file) if File.exist?(cache_file)
    example.run
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
      Hydra::Works::AddFileToFileSet.call(file_set2, pmf, :preservation_master_file)
      Hydra::Works::AddFileToFileSet.call(file_set3, pdf, :preservation_master_file)
      work.ordered_members << file_set
      work.ordered_members << file_set2
      work.ordered_members << file_set3
      work.save!
    end

    after do
      work.ordered_members = []
      work.save!
    end

    describe "#build_manifest class method" do
      context "when a manifest cache file exists" do
        before do
          described_class.regenerate_manifest(presenter: presenter, curation_concern: work)
        end

        it "renders cached file" do
          service = described_class.new(presenter: presenter, curation_concern: work)
          allow(described_class).to receive(:new).and_return(service)
          expect(cache_file).to exist
          expect(service).not_to receive(:regenerate_manifest_file)
          expect(service).to receive(:render_manifest_file)
          described_class.build_manifest(presenter: presenter, curation_concern: work)
        end
      end

      context 'when no manifest cache file exists' do
        it 'saves a placehoder manifest file' do
          service = described_class.new(presenter: presenter, curation_concern: work)
          allow(described_class).to receive(:new).and_return(service)
          allow(service).to receive(:regenerate_manifest_file).and_return(nil)
          described_class.build_manifest(presenter: presenter, curation_concern: work)
          placeholder_values = JSON.parse(File.open(cache_file).read)
          expect(placeholder_values["label"]).to eq "Content is being assembled - please return soon"
        end

        it 'queues regenerating the manifest file' do
          service = described_class.new(presenter: presenter, curation_concern: work)
          allow(described_class).to receive(:new).and_return(service)
          expect(service).not_to receive(:render_manifest_file)
          expect(service).to receive(:regenerate_manifest_file)
          described_class.build_manifest(presenter: presenter, curation_concern: work)
        end

        it 'saves manifest with correct data upon manifest regeneration' do
          described_class.build_manifest(presenter: presenter, curation_concern: work)
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
          expect(response_values["metadata"][1]["value"]).to eq "<a href=\"http://rightsstatements.org/vocab/InC/1.0/\">In Copyright</a>"
          expect(response_values["metadata"][2]["label"]).to eq "Identifier"
          expect(response_values["metadata"][2]["value"]).to eq work.id
          expect(response_values).to include "sequences"
          expect(response_values["sequences"].first["@type"]).to include "sc:Sequence"
          expect(response_values["sequences"].first["@id"]).to include "/iiif/#{work.id}/manifest/sequence/normal"
          expect(response_values["sequences"][0]["canvases"][0]["@id"]).to include "/iiif/#{work.id}/manifest/canvas/#{file_set.id}"
          path = "/images/#{file_set.id}%2Ffiles%2F#{file_set.service_file.id.split('/').last}/full/600,/0/default.jpg"
          expect(response_values["sequences"][0]["canvases"][0]["images"][0]["resource"]["@id"]).to include(path)
          expect(response_values["sequences"][0]["canvases"][1]["@id"]).to include "/iiif/#{work.id}/manifest/canvas/#{file_set2.id}"
          path = "/images/#{file_set2.id}%2Ffiles%2F#{file_set2.preservation_master_file.id.split('/').last}/full/600,/0/default.jpg"
          expect(response_values["sequences"][0]["canvases"][1]["images"][0]["resource"]["@id"]).to include(path)
        end

        it 'only keeps the newly generated manifest upon completion of manifest regeneration' do
          File.open(Rails.root.join('tmp', "outdated_manifest_#{identifier}"), 'w+') do |f|
            f.write("outdated manifest")
          end
          described_class.build_manifest(presenter: presenter, curation_concern: work)
          manifest_file_paths = Dir.glob(Rails.root.join('tmp').to_s + '/*').select do |path|
            path.ends_with?("_#{work.id}")
          end
          expect(manifest_file_paths). to eq([cache_file.to_s])
        end
      end
    end

    describe "#regenerate_manifest class method" do
      it "queues regenerating the manifest file" do
        service = described_class.new(presenter: presenter, curation_concern: work)
        allow(described_class).to receive(:new).and_return(service)
        expect(service).to receive(:regenerate_manifest_file)
        described_class.regenerate_manifest(presenter: presenter, curation_concern: work)
      end
    end

    context "#regenerate_manifest_file instance method" do
      it "queues regenerating the manifest file" do
        service = described_class.new(presenter: presenter, curation_concern: work)
        expect(ManifestPersistenceJob).to receive(:perform_later)
        service.regenerate_manifest_file
      end
    end

    describe "#iiif_url and #info_url instance methods" do
      let(:service) { described_class.new(curation_concern: file_set) }

      context "for localhost" do
        it "returns appropriate iiif_url and info_url" do
          expect(service.iiif_url).to include "/images/#{file_set.id}%2Ffiles%2F#{file_set.service_file.id.split('/').last}/full/600,/0/default.jpg"
          expect(service.info_url).to include "/images/#{file_set.id}%2Ffiles%2F#{file_set.service_file.id.split('/').last}"
        end
      end

      context "for iiif_server" do
        around do |example|
          ENV['IIIF_SERVER_URL'] = 'example.com/iiif/2/'
          ENV['FEDORA_ADAPTER'] = 's3'
          example.run
          ENV['IIIF_SERVER_URL'] = nil
          ENV['FEDORA_ADAPTER'] = nil
        end

        it "returns appropriate iiif_url" do
          expect(service.iiif_url).to include "example.com/iiif/2/"
          expect(service.info_url).to include "example.com/iiif/2/"
        end
      end
    end

    describe "#sequence_rendering" do
      it "something here" do
        expect(service.send(:sequence_rendering).first["@id"]).to eq("http://example.com/downloads/508hdr7srq-cor")
      end
    end
  end
end
