# frozen_string_literal: true
require 'rails_helper'

RSpec.describe ManifestPersistenceJob, :clean do
  context "#image_concerns instance method" do
    let(:work) { FactoryBot.create(:public_generic_work) }
    let(:file_set)  { FactoryBot.create(:file_set, read_groups: ['public']) }
    let(:file_set2) { FactoryBot.create(:file_set, read_groups: ['public']) }
    let(:file_set3) { FactoryBot.create(:file_set, id: '608hdr7srt-cor', read_groups: ['public']) }
    let(:pmf) { File.open(fixture_path + '/book_page/0003_preservation_master.tif') }
    let(:sf) { File.open(fixture_path + '/book_page/0003_service.jpg') }
    let(:pdf) { File.open(fixture_path + '/sample-file.pdf') }
    let(:child_work) { FactoryBot.create(:public_generic_work) }

    before do
      Hydra::Works::AddFileToFileSet.call(file_set, pmf, :preservation_master_file)
      Hydra::Works::AddFileToFileSet.call(file_set, sf, :service_file)
      Hydra::Works::AddFileToFileSet.call(file_set2, pmf, :preservation_master_file)
      Hydra::Works::AddFileToFileSet.call(file_set3, pdf, :preservation_master_file)
      work.ordered_members << file_set
      work.ordered_members << file_set2
      work.ordered_members << file_set3
      work.ordered_members << child_work
      work.save!
    end

    after do
      work.ordered_members = []
      work.save!
    end

    it "returns file_set_ids" do
      expect(described_class.new.send(:image_concerns, work)).to match_array [file_set.id, file_set2.id, file_set3.id]
    end
  end

  describe "#perform" do
    let(:work_id) { 'work-123' }
    let(:key) { "cachekey_#{work_id}" }
    let(:work) { instance_double(CurateGenericWork, ordered_member_ids: [], child_work_ids: []) }
    let(:job_args) do
      { key:, solr_doc: SolrDocument.new('id' => work_id), root_url: "http://example.com/iiif/#{work_id}/manifest",
        manifest_metadata: [], sequence_rendering: [], curation_concern_id: work_id }
    end

    around do |example|
      Dir.mktmpdir do |dir|
        ENV['IIIF_MANIFEST_CACHE'] = dir
        example.run
      ensure
        ENV['IIIF_MANIFEST_CACHE'] = nil
      end
    end

    before do
      allow(CurateGenericWork).to receive(:find).with(work_id).and_return(work)
    end

    it 'persists the manifest and clears pending markers for the work' do
      cache = ENV['IIIF_MANIFEST_CACHE']
      FileUtils.touch(File.join(cache, "#{key}.pending"))
      FileUtils.touch(File.join(cache, "oldkey_#{work_id}.pending"))
      allow(ApplicationController).to receive(:render).and_return('{"label":"manifest"}')

      described_class.perform_now(**job_args)

      expect(File.read(File.join(cache, key))).to eq '{"label":"manifest"}'
      expect(Dir.children(cache)).to eq [key]
    end

    it 're-enqueues itself with a delay when a retryable error is raised' do
      allow(ApplicationController).to receive(:render).and_raise(Ldp::HttpError, 'Fedora unavailable')

      expect { described_class.perform_now(**job_args) }.to have_enqueued_job(described_class)
      expect(File).not_to exist(File.join(ENV['IIIF_MANIFEST_CACHE'], key))
    end
  end
end
