# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CurateMapper do
  subject(:mapper) { described_class.new }

  let(:metadata) do
    {
      "administrative_unit" => "Stuart A. Rose Manuscript, Archives and Rare Book Library|Some other library",
      "content_type" => 'still image',
      "date_created" => "1985-11-01",
      "rights_statement_text" => "Emory University does not control copyright for this image.",
      "rights_statement" => "http://rightsstatements.org/vocab/InC/1.0/",
      "title" => "what an awesome title",
      "visibility" => "Emory Network"
    }
  end

  before { mapper.metadata = metadata }

  it 'is configured to be the zizia metadata mapper' do
    expect(Zizia.config.metadata_mapper_class).to eq described_class
  end

  context "#administrative_unit" do
    it "maps directly" do
      expect(mapper.administrative_unit).to contain_exactly(
        "Stuart A. Rose Manuscript, Archives and Rare Book Library",
        "Some other library"
      )
    end
  end

  context "#content_type" do
    context "when the string matches exactly" do
      let(:metadata) do
        {
          "title" => "my title",
          "content_type" => 'Still image'
        }
      end
      it "maps content_type to a uri" do
        expect(mapper.content_type).to eq "http://id.loc.gov/vocabulary/resourceTypes/img"
      end
    end
    context "when the string matches except for capitalization and whitespace" do
      let(:metadata) do
        {
          "title" => "my title",
          "content_type" => 'still image  '
        }
      end
      it "maps content_type to a uri" do
        expect(mapper.content_type).to eq "http://id.loc.gov/vocabulary/resourceTypes/img"
      end
    end
    context "when the CSV has a uri instead of a string" do
      let(:metadata) do
        {
          "title" => "my title",
          "content_type" => 'http://id.loc.gov/vocabulary/resourceTypes/img'
        }
      end
      it "maps content_type to the uri" do
        expect(mapper.content_type).to eq "http://id.loc.gov/vocabulary/resourceTypes/img"
      end
    end
  end

  context "#date_created" do
    it "maps the date_created field" do
      expect(mapper.date_created)
        .to contain_exactly("1985-11-01")
    end
  end

  context "#rights_statement_text" do
    it "maps the rights_statement_text field" do
      expect(mapper.rights_statement_text)
        .to contain_exactly("Emory University does not control copyright for this image.")
    end
  end

  context "#rights_statement" do
    it "maps the rights_statement field when it's valid" do
      expect(mapper.rights_statement).to eq "http://rightsstatements.org/vocab/InC/1.0/"
    end
    context "invalid rights statement" do
      let(:metadata) do
        {
          "rights_statement" => "http://badrightsstatements.org/vocab/InC/1.0/"
        }
      end
      it "raises an exception when it isn't valid" do
        expect { mapper.rights_statement }.to raise_error RuntimeError
      end
    end
  end

  context "#title" do
    it "maps the required title field" do
      expect(mapper.map_field(:title))
        .to contain_exactly("what an awesome title")
    end
  end

  context "#visibility" do
    context "Emory Network" do
      let(:metadata) do
        {
          "title" => "my title",
          "content_type" => "http://id.loc.gov/vocabulary/resourceTypes/img",
          "visibility" => "Emory Network"
        }
      end
      it "gives authenticated" do
        expect(mapper.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
      end
    end
  end

  describe '#fields' do
    it 'has expected fields' do
      expect(mapper.fields).to include(
        :title,
        :visibility
      )
    end
  end
end
