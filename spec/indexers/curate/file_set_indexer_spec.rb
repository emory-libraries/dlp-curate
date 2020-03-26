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
  end
end
