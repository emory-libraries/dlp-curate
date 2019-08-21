# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CurateMapper do
  subject(:mapper) { described_class.new }

  let(:metadata) do
    {
      "abstract" => "Verso: Advertisting, High Boy Cigarettes. Photo by: Teenie Harris, staff (black) photographer for Pittsburg Courier",
      "administrative_unit" => "Stuart A. Rose Manuscript, Archives and Rare Book Library",
      "content_genre" => "black-and-white photographs",
      "contact_information" => "Stuart A. Rose Manuscript, Archives and Rare Book Library rose.library@emory.edu",
      "content_type" => 'still image',
      "copyright_date" => "1985-11-01",
      "creator" => "Harris, Teenie, 1908-1998.",
      "data_classification" => "Confidential|Internal",
      "date_created" => "1985-11-01",
      "date_issued" => "Unknown",
      "holding_repository" => "Stuart A. Rose Manuscript, Archives and Rare Book Library",
      "institution" => "Emory University",
      "keywords" => "Tangerine|Blueberry",
      "legacy_ark" => "ark://abc/123",
      "legacy_identifier" => "dams:152815|MSS1218_B001_I002",
      "local_call_number" => "MSS 1218",
      "note" => "This is a note.",
      "place_of_production" => "London",
      "primary_language" => "English",
      "publisher" => "Gutenberg",
      "rights_statement" => "http://rightsstatements.org/vocab/InC/1.0/",
      "rights_statement_text" => "Emory University does not control copyright for this image.",
      "subject_geo" => "Ghana.|Africa.",
      "subject_names" => "Mouvement national congolais.|Okito, Joseph.|Lumumba, Patrice, 1925-1961.",
      "subject_topics" => "Snowblowers.|Snow.|Air bases.|Towers.",
      "table_of_contents" => "Thing 1. Thing 2.",
      "title" => "what an awesome title",
      "uniform_title" => "Pittsburg courier.",
      "visibility" => "Emory Network"
    }
  end

  before { mapper.metadata = metadata }

  it 'is configured to be the zizia metadata mapper' do
    expect(Zizia.config.metadata_mapper_class).to eq described_class
  end

  context "#abstract" do
    it "maps the abstract field" do
      expect(mapper.abstract).to eq "Verso: Advertisting, High Boy Cigarettes. Photo by: Teenie Harris, staff (black) photographer for Pittsburg Courier"
    end
  end

  context "#administrative_unit" do
    it "does its best to match the configured controlled vocabulary term" do
      expect(mapper.administrative_unit).to eq "Stuart A. Rose Manuscript, Archives, and Rare Book Library"
    end
  end

  context "#content_genre" do
    it "maps the content_genre field" do
      expect(mapper.content_genre).to eq ["black-and-white photographs"]
    end
  end

  context "#contact_information" do
    it "maps the contact_information field" do
      expect(mapper.contact_information).to eq "Stuart A. Rose Manuscript, Archives and Rare Book Library rose.library@emory.edu"
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

  context "#copyright_date" do
    it "maps the copyright_date field" do
      expect(mapper.copyright_date).to eq "1985-11-01"
    end
  end

  context "#creator" do
    it "maps the creator field" do
      expect(mapper.creator).to eq ["Harris, Teenie, 1908-1998."]
    end
  end

  context "#data_classification" do
    it "maps the data_classification field" do
      expect(mapper.data_classification).to contain_exactly("Confidential", "Internal")
    end
  end

  context "#date_created" do
    it "maps the date_created field" do
      expect(mapper.date_created).to eq "1985-11-01"
    end
  end

  context "#date_issued" do
    it "maps the date_issued field" do
      expect(mapper.date_issued).to eq "Unknown"
    end
  end

  context "#holding_repository" do
    it "maps the holding_repository field" do
      expect(mapper.holding_repository).to eq "Stuart A. Rose Manuscript, Archives and Rare Book Library"
    end
  end

  context "#institution" do
    it "maps the institution field" do
      expect(mapper.institution).to eq "Emory University"
    end
  end

  context "#keywords" do
    it "maps the keywords field" do
      expect(mapper.keywords).to contain_exactly("Tangerine", "Blueberry")
    end
  end

  context "#legacy_ark" do
    it "maps the legacy_ark field" do
      expect(mapper.legacy_ark).to contain_exactly("ark://abc/123")
    end
  end

  context "#legacy_identifier" do
    it "maps the legacy_identifier field" do
      expect(mapper.legacy_identifier).to contain_exactly("dams:152815", "MSS1218_B001_I002")
    end
  end

  context "#local_call_number" do
    it "maps the local_call_number field" do
      expect(mapper.local_call_number).to eq "MSS 1218"
    end
  end

  context "#place_of_production" do
    it "maps the place_of_production field" do
      expect(mapper.place_of_production).to eq "London"
    end
  end

  context "#note" do
    it "maps the note field" do
      expect(mapper.note).to eq ["This is a note."]
    end
  end

  context "#primary_language" do
    it "maps the primary_language field" do
      expect(mapper.primary_language).to eq "English"
    end
  end

  context "#publisher" do
    it "maps the publisher field" do
      expect(mapper.publisher).to eq "Gutenberg"
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

  context "#subject_geo" do
    it "maps the subject_geo field" do
      expect(mapper.subject_geo)
        .to contain_exactly("Ghana.", "Africa.")
    end
  end

  context "#subject_names" do
    it "maps the subject_names field" do
      expect(mapper.subject_names)
        .to contain_exactly("Mouvement national congolais.", "Okito, Joseph.", "Lumumba, Patrice, 1925-1961.")
    end
  end

  context "#subject_topics" do
    it "maps the subject_topics field" do
      expect(mapper.subject_topics)
        .to contain_exactly("Snowblowers.", "Snow.", "Air bases.", "Towers.")
    end
  end

  context "#table_of_contents" do
    it "maps the table_of_contents field" do
      expect(mapper.table_of_contents)
        .to eq "Thing 1. Thing 2."
    end
  end

  context "#title" do
    it "maps the required title field" do
      expect(mapper.map_field(:title))
        .to contain_exactly("what an awesome title")
    end
  end

  context "#uniform_title" do
    it "maps the uniform_title field" do
      expect(mapper.uniform_title)
        .to eq "Pittsburg courier."
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
