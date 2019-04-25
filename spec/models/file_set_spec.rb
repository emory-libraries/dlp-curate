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
end
