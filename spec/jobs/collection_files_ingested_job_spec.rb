# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CollectionFilesIngestedJob, :clean, perform_enqueued: [AttachFilesToWorkJob] do
  let(:collection) { FactoryBot.create(:collection_lw, user: admin) }
  let(:user) { FactoryBot.create(:user) }
  let(:work1) { FactoryBot.build(:work, user: admin) }
  let(:file_set) { FactoryBot.create(:file_set, user: admin, title: ["Test title"], pcdm_use: "Primary Content") }
  let(:file) { File.open(fixture_path + '/sun.png') }
  let(:admin) { FactoryBot.create :admin }

  let(:collection_attrs) do
    {
      title:               ['Robert Langmuir African American Photograph Collection'],
      institution:         'Emory University',
      creator:             ['Langmuir, Robert, collector.'],
      holding_repository:  ['Stuart A. Rose Manuscript, Archives, and Rare Book Library'],
      administrative_unit: ['Stuart A. Rose Manuscript, Archives, and Rare Book Library'],
      contact_information: 'Woodruff Library',
      abstract:            'Collection of photographs depicting African American life and culture collected by Robert Langmuir.',
      primary_language:    'English',
      local_call_number:   'MSS1218',
      keywords:            ['keyword1', 'keyword2']
    }
  end

  before do
    collection_attrs.each do |k, v|
      collection.send((k.to_s + "=").to_sym, v)
    end
    Hydra::Works::AddFileToFileSet.call(file_set, file, :preservation_master_file)
    work1.ordered_members << file_set
    work1.member_of_collections << collection
    Curate::FileSetIndexer.new(file_set).generate_solr_document
    work1.save!
  end

  after do
    File.delete("config/emory/collection-counts-for-#{Time.current.strftime('%Y%m%dT%H%M')}.json") if File.exist?("config/emory/collection-counts-for-#{Time.current.strftime('%Y%m%dT%H%M')}.json")
  end

  it 'produces a file in config/emory folder' do
    described_class.perform_now
    expect(File).to exist("config/emory/collection-counts-for-#{Time.current.strftime('%Y%m%dT%H%M')}.json")
  end

  context "created file" do
    it 'has the right json' do
      described_class.perform_now
      file = File.open("config/emory/collection-counts-for-#{Time.current.strftime('%Y%m%dT%H%M')}.json")
      file_content = file.read
      parsed_json = JSON.parse(file_content).first

      expect([parsed_json['collection_title'], parsed_json['work_total'], parsed_json['fileset_total'], parsed_json['file_total']]).to eq(
        ["Robert Langmuir African American Photograph Collection", 1, 1, 1]
      )
    end
  end
end
