# frozen_string_literal: true
require 'rails_helper'

RSpec.describe FileSetCleanUpJob, :clean do
  let(:csv_path)    { File.join("config/emory/index_file_set_results.csv") }
  let(:csv)         { IO.read(csv_path) }
  let(:file)        { File.open(fixture_path + '/book_page/0003_preservation_master.tif') }
  let(:file_set)    { FactoryBot.create(:file_set) }

  after do
    File.delete(csv_path) if File.exist?(csv_path)
  end

  context 'file_set is indexed incorrectly' do
    before do
      allow(SolrDocument).to receive_message_chain(:find, :mime_type)
      Hydra::Works::AddFileToFileSet.call(file_set, file, :preservation_master_file)
      described_class.perform_now
    end

    it 'reindexes file_set' do
      expect(csv).to include("#{file_set.id},Fileset not indexed,Fixed")
    end
  end

  context 'file_set thumbnail_path in solr is incorrect' do
    before do
      allow(SolrDocument).to receive_message_chain(:find, :thumbnail_path).and_return("/assets/default-f936e9c3ea7a38e2c2092099586a71380b11258697b37fb4df376704495a849a.png")
      allow(SolrDocument).to receive_message_chain(:find, :mime_type).and_return('image/tiff')
      Hydra::Works::AddFileToFileSet.call(file_set, file, :preservation_master_file)
      described_class.perform_now
    end

    it 'regenerates thumbnail and fixes thumbnail_path in solr' do
      expect(csv).to include("#{file_set.id},Thumbnail_path mismatch in solr_doc,Queued")
    end
  end
end
