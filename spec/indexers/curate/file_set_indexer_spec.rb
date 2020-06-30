# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Curate::FileSetIndexer, clean: true do
  let(:file_set) do
    FileSet.new(
      id:    '508hdr7srq-cor',
      title: ['something']
    )
  end
  let(:pmf) { File.open(fixture_path + '/book_page/0003_preservation_master.tif') }
  let(:sf)  { File.open(fixture_path + '/book_page/0003_service.jpg') }
  before do
    Hydra::Works::AddFileToFileSet.call(file_set, pmf, :preservation_master_file)
    Hydra::Works::AddFileToFileSet.call(file_set, sf, :service_file)
  end

  describe "#generate_solr_doc" do
    subject :indexer do
      described_class.new(file_set).generate_solr_document
    end

    it "saves sha1 for all available files" do
      expect(indexer['sha1_tesim']).to include(file_set.preservation_master_file.checksum.uri.to_s,
                                               file_set.service_file.checksum.uri.to_s)
    end

    describe "#other_events" do
      subject :other_events do
        described_class.new(file_set).send(:other_events)
      end

      let(:event) { JSON.parse(other_events.first) }

      before do
        # we are emptying preservation_events so that we can call
        # `other_events` method in the class and have it return the
        # nested object rather than the preservation_event itself.
        file_set.preservation_event = []
        file_set.save!
      end

      it "saves nested object as preservation_event in solr" do
        expect(event['event_details']).to eq(["No viruses found"])
        expect(event['event_type']).to eq("Virus Check")
        expect(event['software_version']).to eq("ClamAV 0.101.4")
        expect(indexer['preservation_event_tesim'].first.first).to include("{\"event_details\":[\"No viruses found\"],\"event_type\":\"Virus Check\"")
      end
    end
  end
end
