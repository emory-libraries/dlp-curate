require 'rails_helper'

RSpec.describe FileSet do
  describe '#related_files' do
    let!(:f1) { described_class.new }

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

  describe "metadata" do
    let(:file_set) { described_class.new }
    it 'has properties from characterization metadata' do
      expect(file_set).to respond_to(:file_path)
      expect(file_set).to respond_to(:creating_application_name)
      expect(file_set).to respond_to(:creating_os)
      expect(file_set).to respond_to(:puid)
    end
  end
end
