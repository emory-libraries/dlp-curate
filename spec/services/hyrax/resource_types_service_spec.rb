require 'rails_helper'

RSpec.describe Hyrax::ResourceTypesService do
  describe "select_options" do
    subject(:options) { described_class.select_options }

    it "has a select list" do
      expect(options.first).to eq ["Artifact", "http://id.loc.gov/vocabulary/resourceTypes/art"]
      expect(options.size).to eq 15
    end
  end

  describe "label" do
    subject { described_class.label("http://id.loc.gov/vocabulary/resourceTypes/art") }

    it { is_expected.to eq 'Artifact' }
  end

  describe "microdata_type" do
    subject { described_class.microdata_type(id) }

    context "when the id is in the i18n" do
      let(:id) { "Map or Cartographic Material" }

      it { is_expected.to eq 'http://schema.org/Map' }
    end

    context "when the id is not in the i18n" do
      let(:id) { "missing" }

      it { is_expected.to eq 'http://schema.org/CreativeWork' }
    end

    context "when the id is nil" do
      let(:id) { nil }

      it { is_expected.to eq 'http://schema.org/CreativeWork' }
    end
  end
end
