# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FileSet, :perform_enqueued, :clean do
  describe '#related_files' do
    let!(:f1) { FactoryBot.create(:file_set, content: File.open(Rails.root.join('spec', 'fixtures', 'world.png'))) }

    describe "#original_file" do
      it "is the same as the preservation_master_file" do
        expect(f1.original_file).to eq(f1.preservation_master_file)
      end
    end

    context 'when there are no related files' do
      it 'returns an empty array' do
        expect(f1.related_files).to eq []
      end
    end

    context 'when there are related files' do
      let(:parent_work)   { FactoryBot.create(:work_with_files) }
      let(:f1)            { parent_work.file_sets.first }
      let(:f2)            { parent_work.file_sets.last }
      let(:related_files) { f1.reload.related_files }

      it 'returns all files contained in parent work(s) but excludes itself' do
        expect(related_files).to include(f2)
        expect(related_files).not_to include(f1)
      end
    end
  end

  it "multiple pcdm_use error" do
    expect { described_class.new(pcdm_use: [described_class::PRIMARY]) }.to raise_error(ArgumentError)
  end
  describe "#primary" do
    context 'when primary' do
      subject(:file_set) { described_class.new(pcdm_use: described_class::PRIMARY) }
      its(:pcdm_use) { is_expected.to eq described_class::PRIMARY }
      it { is_expected.to be_primary }
      it { is_expected.not_to be_supplementary }
    end
  end

  describe "#supplementary" do
    context 'when supplementary' do
      subject(:file_set) { described_class.new(pcdm_use: described_class::SUPPLEMENTAL) }
      its(:pcdm_use) { is_expected.to eq described_class::SUPPLEMENTAL }
      it { is_expected.not_to be_primary }
      it { is_expected.to be_supplementary }
    end
  end

  describe '#visibility' do
    subject(:file_set) { FactoryBot.build(:file_set, visibility: open) }

    let(:open)       { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
    let(:restricted) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }
    let(:authenticated) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED }
    let(:lease) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LEASE }
    let(:embargo) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO }

    it 'can set to restricted' do
      expect { file_set.visibility = restricted }
        .to change { file_set.visibility }
        .to restricted
    end

    it 'can set to authenticated' do
      expect { file_set.visibility = authenticated }
        .to change { file_set.visibility }
        .to authenticated
    end
  end

  describe "metadata" do
    let(:file_set) { described_class.new }
    it 'has properties from characterization metadata' do
      expect(file_set).to respond_to(:file_path)
      expect(file_set).to respond_to(:creating_application_name)
      expect(file_set).to respond_to(:creating_os)
      expect(file_set).to respond_to(:puid)
    end

    it 'has a preservation event which is a PreservationEvent object' do
      expect(file_set.preservation_event.build).to be_instance_of PreservationEvent
    end
  end

  # This spec is borrowed and modified from `Hydra::Works::VirusCheck`
  context "with ClamAV" do
    let(:file) do
      Hydra::PCDM::File.new do |f|
        f.content = File.new(File.join(fixture_path, 'sample-file.pdf'))
        f.original_name = 'sample-file.pdf'
      end
    end
    let(:file_set)         { FileSet.new } # We create an empty file_set and walk through virus-checking
    let(:file_set_with_id) { FactoryBot.create(:file_set) } # We save the preservation_events on this file_set object

    before do
      allow(file_set).to receive(:preservation_master_file) { file } # this is necessary since we are not performing any ingest
      allow(FileSet).to receive(:find).and_return(file_set_with_id) # this is mocked because we need a file_set with an ID
      # on L#60 in the FileSet model.
    end

    context 'with an infected file' do
      before do
        expect(Hydra::Works::VirusCheckerService).to receive(:file_has_virus?).and_return(true)
      end
      it 'fails to save' do
        expect(file_set.save).to eq false
        expect(file_set_with_id.preservation_event.first.event_details).to eq ['Virus was found in file: sample-file.pdf']
        expect(file_set_with_id.preservation_event.first.outcome).to eq ['Failure']
      end
      it 'fails to validate' do
        expect(file_set.validate).to eq false
      end
    end

    context 'with a clean file' do
      it 'does not detect viruses' do
        expect(Hydra::Works::VirusCheckerService).to receive(:file_has_virus?).and_return(false)
        expect(file_set).not_to be_viruses
        expect(file_set_with_id.preservation_event.first.event_details).to eq ['No viruses found']
        expect(file_set_with_id.preservation_event.first.outcome).to eq ['Success']
      end
    end
  end

  describe "#preferred_file" do
    let(:file_set) { FactoryBot.create(:file_set) }
    let(:pmf)      { File.open(fixture_path + '/book_page/0003_preservation_master.tif') }
    let(:sf)       { File.open(fixture_path + '/book_page/0003_service.jpg') }
    let(:imf)      { File.open(fixture_path + '/book_page/0003_intermediate.jp2') }

    context 'when service_file is present' do
      before do
        Hydra::Works::AddFileToFileSet.call(file_set, pmf, :preservation_master_file)
        Hydra::Works::AddFileToFileSet.call(file_set, sf, :service_file)
        Hydra::Works::AddFileToFileSet.call(file_set, imf, :intermediate_file)
      end

      it 'returns service_file symbol' do
        expect(file_set.preferred_file).to eq(:service_file)
      end
    end

    context 'when service_file is absent but intermediate_file is present' do
      before do
        Hydra::Works::AddFileToFileSet.call(file_set, pmf, :preservation_master_file)
        Hydra::Works::AddFileToFileSet.call(file_set, imf, :intermediate_file)
      end

      it 'returns intermediate_file symbol' do
        expect(file_set.preferred_file).to eq(:intermediate_file)
      end
    end

    context 'when only the preservation is present' do
      before do
        Hydra::Works::AddFileToFileSet.call(file_set, pmf, :preservation_master_file)
      end

      it 'returns preservation_master_file symbol' do
        expect(file_set.preferred_file).to eq(:preservation_master_file)
      end
    end
  end
end
