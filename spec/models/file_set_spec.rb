require 'rails_helper'

RSpec.describe FileSet do
  it "multiple pcdm_use error" do
    expect { described_class.new(pcdm_use: [described_class::PRIMARY]) }.to raise_error(ArgumentError)
  end
  describe "#primary" do
    context 'when primary' do
      subject(:file_set) { described_class.new(pcdm_use: described_class::PRIMARY) }
      its(:pcdm_use) { is_expected.to eq described_class::PRIMARY }
      it { is_expected.to be_primary }
      it { is_expected.not_to be_supplemental }
    end
  end

  describe "#supplemental" do
    context 'when supplemental' do
      subject(:file_set) { described_class.new(pcdm_use: described_class::SUPPLEMENTAL) }
      its(:pcdm_use) { is_expected.to eq described_class::SUPPLEMENTAL }
      it { is_expected.not_to be_primary }
      it { is_expected.to be_supplemental }
    end
  end
end
