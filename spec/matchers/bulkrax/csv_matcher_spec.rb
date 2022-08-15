# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Bulkrax::CsvMatcher, :clean do
  let(:matcher) { described_class.new(split: true) }

  context '#parse_title' do
    it 'cleans up a string passed to it' do
      hello = 'Hello! '.dup
      expect(matcher.parse_title(hello)).to eq('Hello!')
    end

    it 'returns Unknown Title when left blank' do
      expect(matcher.parse_title('')).to eq('Unknown Title')
    end
  end

  context '#parse_content_type' do
    context "when the string matches exactly" do
      it 'produces the right link' do
        expect(matcher.parse_content_type('Still image')).to eq('http://id.loc.gov/vocabulary/resourceTypes/img')
      end
    end

    context "when the string matches except for capitalization and whitespace" do
      it 'produces the right link' do
        expect(matcher.parse_content_type('still image  ')).to eq('http://id.loc.gov/vocabulary/resourceTypes/img')
      end
    end

    context "when passed an uri instead of a string" do
      it 'produces the right link' do
        expect(matcher.parse_content_type('http://id.loc.gov/vocabulary/resourceTypes/img')).to(
          eq('http://id.loc.gov/vocabulary/resourceTypes/img')
        )
      end
    end
  end

  context '#parse_rights_statement' do
    context 'when valid' do
      it 'produces the right link' do
        expect(matcher.parse_rights_statement('http://rightsstatements.org/vocab/InC/1.0/')).to(
          eq('http://rightsstatements.org/vocab/InC/1.0/')
        )
      end
    end

    context 'when invalid' do
      it "raises an exception when it isn't valid" do
        expect { matcher.parse_rights_statement("http://badrightsstatements.org/vocab/InC/1.0/") }.to(
          raise_error RuntimeError
        )
      end
    end
  end

  context '#parse_data_classifications' do
    it "maps the data_classifications field" do
      expect(matcher.parse_data_classifications('Confidential')).to eq('Confidential')
      expect(matcher.parse_data_classifications('Internal')).to eq('Internal')
      expect { matcher.parse_data_classifications('Super Duper Top Secret') }.to(raise_error RuntimeError)
    end
  end

  context '#parse_visibility' do
    it "gives authenticated" do
      expect(matcher.parse_visibility('Emory Network')).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
    end
  end

  context '#parse_pcdm_use' do
    context "primary content" do
      it "maps pcdm_use to FileSet:PRIMARY" do
        expect(matcher.parse_pcdm_use("Primary Content")).to eq(FileSet::PRIMARY)
      end
    end

    context "supplemental" do
      it "maps pcdm_use to FileSet:SUPPLEMENTAL" do
        expect(matcher.parse_pcdm_use("supplemental Content")).to eq(FileSet::SUPPLEMENTAL)
      end
    end

    context "supplemental preservation" do
      it "maps pcdm_use to FileSet:PRESERVATION" do
        expect(matcher.parse_pcdm_use("Supplemental preservation")).to eq(FileSet::PRESERVATION)
      end
    end

    context "nilness" do
      it "maps pcdm_use to primary content" do
        expect(matcher.parse_pcdm_use(nil)).to eq(FileSet::PRIMARY)
        expect(matcher.parse_pcdm_use('')).to eq(FileSet::PRIMARY)
      end
    end
  end
end
