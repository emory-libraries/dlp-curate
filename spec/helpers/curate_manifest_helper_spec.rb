# frozen_string_literal: true
require 'rails_helper'

RSpec.describe CurateManifestHelper, :clean do
  let(:fs)       { FactoryBot.create(:file_set, id: '608hdr7srt-cor', title: ['foo']) }
  let(:solr_doc) { SolrDocument.new(attributes) }
  let(:attributes) do
    {
      "id" => '608hdr7srt-cor',
      "label_tesim" => [fs.title.first],
      "has_model_ssim" => ["FileSet"],
      "date_created_tesim" => ['an unformatted date'],
      "date_modified_dtsi" => "2019-11-11T18:20:32Z",
      "depositor_tesim" => 'example_user',
      "mime_type_ssi" => "application/pdf"
    }
  end

  before do
    allow(SolrDocument).to receive(:find).and_return(solr_doc)
  end

  describe "#sequence_rendering" do
    subject :rendering do
      described_class.new.build_rendering(fs.id)
    end

    it "returns rendering hash" do
      expect(rendering["@id"]).to include("/downloads/608hdr7srt-cor")
      expect(rendering["format"]).to eq("application/pdf")
      expect(rendering["label"]).to eq("Download whole resource: foo")
    end
  end
end
