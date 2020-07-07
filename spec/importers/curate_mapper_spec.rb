# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CurateMapper do
  subject(:mapper) { described_class.new }

  let(:metadata) do
    {
      "abstract" => "Verso: Advertisting, High Boy Cigarettes. Photo by: Teenie Harris, staff (black) photographer for Pittsburg Courier",
      "access_restriction_notes" => "Don't show this to anyone.",
      "administrative_unit" => "Stuart A. Rose Manuscript, Archives and Rare Book Library",
      "author_notes" => "Written while intoxicated.",
      "conference_name" => "Exposition universelle de 1878 (Paris, France)",
      "conference_dates" => "2015-01-08 TO 2015-01-13",
      "content_genres" => "black-and-white photographs|photographic negatives",
      "contact_information" => "Stuart A. Rose Manuscript, Archives and Rare Book Library rose.library@emory.edu",
      "content_type" => 'still image',
      "contributors" => "Craigie, Dorothy, 1901- collector. GEU|Greene, Graham, 1904-1991, collector. GEU",
      "copyright_date" => "1985-11-01",
      "creator" => "Harris, Teenie, 1908-1998.",
      "data_classifications" => "Confidential|Internal",
      "data_collection_dates" => "2020-01-01",
      "data_producers" => "Petrol",
      "data_source_notes" => "Off the floor of a bathroom.",
      "date_created" => "1985-11-01",
      "date_issued" => "Unknown",
      "edition" => "2nd edition.",
      "final_published_versions" => "5th edition",
      "geographic_unit" => "Florida",
      "grant_agencies" => "ASCAP",
      "grant_information" => "$1,000,000",
      "holding_repository" => "Stuart A. Rose Manuscript, Archives and Rare Book Library",
      "institution" => "Emory University",
      "internal_rights_note" => "This is my internal rights note.",
      "isbn" => "17728891-6",
      "issn" => "105-196-560",
      "issue" => "260",
      "keywords" => "Tangerine|Blueberry",
      "emory_ark" => "ark://abc/123",
      "other_identifiers" => "dams:152815|MSS1218_B001_I002",
      "local_call_number" => "MSS 1218",
      "notes" => "This is a note.",
      "page_range_end" => "200",
      "page_range_start" => "15",
      "parent_title" => "An older, wiser title",
      "pcdm_use" => nil,
      "place_of_production" => "London",
      "primary_language" => "English",
      "primary_repository_ID" => "1",
      "publisher" => "Gutenberg",
      "related_datasets" => "Dope Books",
      "related_material_notes" => "Some pages are stained.",
      "related_publications" => "The Bible|Dianetics",
      "re_use_license" => "https://creativecommons.org/licenses/by/4.0/",
      "rights_documentation" => "rights@aol.com",
      "rights_holders" => "Unknown",
      "rights_statement" => "http://rightsstatements.org/vocab/InC/1.0/",
      "emory_rights_statements" => "Emory University does not control copyright for this image.",
      "scheduled_rights_review" => "2021-01-02",
      "scheduled_rights_review_note" => "Rip it off the site.",
      "series_title" => "Chatterbox library.",
      "sponsor" => "Shell Oil",
      "staff_notes" => "Got this one done.",
      "subject_geo" => "Ghana.|Africa.",
      "subject_names" => "Mouvement national congolais.|Okito, Joseph.|Lumumba, Patrice, 1925-1961.",
      "subject_time_periods" => "Medieval Times",
      "subject_topics" => "Snowblowers.|Snow.|Air bases.|Towers.",
      "system_of_record_ID" => "990020982660302486",
      "table_of_contents" => "Thing 1. Thing 2.",
      "technical_note" => "Use a Mac.",
      "title" => "what an awesome title",
      "uniform_title" => "Pittsburg courier.",
      "volume" => "10",
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

  context "#access_restriction_notes" do
    it "maps the access_restriction_notes field" do
      expect(mapper.access_restriction_notes).to contain_exactly "Don't show this to anyone."
    end
  end

  context "#administrative_unit" do
    it "does its best to match the configured controlled vocabulary term" do
      expect(mapper.administrative_unit).to eq "Stuart A. Rose Manuscript, Archives, and Rare Book Library"
    end
  end

  context "#author_notes" do
    it "maps the author_notes field" do
      expect(mapper.author_notes).to eq "Written while intoxicated."
    end
  end

  context "#conference_dates" do
    it "maps the conference_dates field" do
      expect(mapper.conference_dates).to eq "2015-01-08 TO 2015-01-13"
    end
  end

  context "#conference_name" do
    it "maps the conference_NAME field" do
      expect(mapper.conference_name).to eq "Exposition universelle de 1878 (Paris, France)"
    end
  end

  context "#content_genres" do
    it "maps the content_genres field" do
      expect(mapper.content_genres).to eq ["black-and-white photographs", "photographic negatives"]
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

  context "#contributors" do
    it "maps the contributors field" do
      expect(mapper.contributors).to contain_exactly("Craigie, Dorothy, 1901- collector. GEU", "Greene, Graham, 1904-1991, collector. GEU")
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

  context "#data_classifications" do
    it "maps the data_classifications field" do
      expect(mapper.data_classifications).to contain_exactly("Confidential", "Internal")
    end
  end

  context "#data_collection_dates" do
    it "maps the data_collection_dates field" do
      expect(mapper.data_collection_dates).to contain_exactly "2020-01-01"
    end
  end

  context "#data_producers" do
    it "maps the data_producers field" do
      expect(mapper.data_producers).to contain_exactly "Petrol"
    end
  end

  context "#data_source_notes" do
    it "maps the data_source_notes field" do
      expect(mapper.data_source_notes).to contain_exactly "Off the floor of a bathroom."
    end
  end

  context "#date_created" do
    it "maps the date_created field" do
      expect(mapper.date_created).to eq "1985-11-01"
    end
  end

  context "#date_digitized" do
    let(:metadata) do
      {
        "title" => "my title",
        "date_digitized" => "1985-11-01"
      }
    end
    it "maps the date_digitized field" do
      expect(mapper.date_digitized).to eq "1985-11-01"
    end
  end

  context "#date_issued" do
    it "maps the date_issued field" do
      expect(mapper.date_issued).to eq "Unknown"
    end
  end

  context "#edition" do
    it "maps the edition field" do
      expect(mapper.edition).to eq "2nd edition."
    end
  end

  context "#extent" do
    let(:metadata) do
      {
        "title" => "my title",
        "extent" => "10.29 x 08.53 inches"
      }
    end
    it "maps the extent field" do
      expect(mapper.extent).to eq "10.29 x 08.53 inches"
    end
  end

  context "#isbn" do
    it "maps the isbn field" do
      expect(mapper.isbn).to eq "17728891-6"
    end
  end

  context "#issn" do
    it "maps the issn field" do
      expect(mapper.issn).to eq "105-196-560"
    end
  end

  context "#final_published_versions" do
    it "maps the final_published_versions field" do
      expect(mapper.final_published_versions).to contain_exactly "5th edition"
    end
  end

  context "#geographic_unit" do
    it "maps the geographic_unit field" do
      expect(mapper.geographic_unit).to eq "Florida"
    end
  end

  context "#grant_agencies" do
    it "maps the grant_agencies field" do
      expect(mapper.grant_agencies).to contain_exactly "ASCAP"
    end
  end

  context "#grant_information" do
    it "maps the grant_information field" do
      expect(mapper.grant_information).to contain_exactly "$1,000,000"
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

  context "#internal_rights_note" do
    it "maps the internal_rights_note field" do
      expect(mapper.internal_rights_note).to eq "This is my internal rights note."
    end
  end

  context "#issue" do
    it "maps the issue field" do
      expect(mapper.issue).to eq "260"
    end
  end

  context "#keywords" do
    it "maps the keywords field" do
      expect(mapper.keywords).to contain_exactly("Tangerine", "Blueberry")
    end
  end

  context "#emory_ark" do
    it "maps the emory_ark field" do
      expect(mapper.emory_ark).to contain_exactly("ark://abc/123")
    end
  end

  context "#other_identifiers" do
    it "maps the other_identifiers field" do
      expect(mapper.other_identifiers).to contain_exactly("dams:152815", "MSS1218_B001_I002")
    end
  end

  context "#legacy_rights" do
    let(:legacy_rights) do
      "Emory University does not control copyright for this image.  This image is made available for individual viewing and reference for educational purposes only such as personal study, preparation for teaching, and research.  Your reproduction, distribution, public display or other re-use of any content beyond a fair use as codified in section 107 of US Copyright Law is at your own risk.  We are always interested in learning more about our collections.  If you have information regarding this photograph, please contact marbl@emory.edu."
    end
    let(:metadata) do
      {
        "title" => "my title",
        "legacy_rights" => legacy_rights
      }
    end
    it "maps the legacy_rights field" do
      expect(mapper.legacy_rights).to eq legacy_rights
    end
  end

  context "#local_call_number" do
    it "maps the local_call_number field" do
      expect(mapper.local_call_number).to eq "MSS 1218"
    end
  end

  context "#parent_title" do
    it "maps the parent_title field" do
      expect(mapper.parent_title).to eq "An older, wiser title"
    end
  end

  context "#place_of_production" do
    it "maps the place_of_production field" do
      expect(mapper.place_of_production).to eq "London"
    end
  end

  context "#related_material_notes" do
    it "maps the related_material_notes field" do
      expect(mapper.related_material_notes).to contain_exactly "Some pages are stained."
    end
  end

  context "#notes" do
    it "maps the notes field" do
      expect(mapper.notes).to eq ["This is a note."]
    end
  end

  context "#page_range_end" do
    it "maps the page_range_end field" do
      expect(mapper.page_range_end).to eq "200"
    end
  end

  context "#page_range_start" do
    it "maps the page_range_start field" do
      expect(mapper.page_range_start).to eq "15"
    end
  end

  context "#pcdm_use" do
    context "primary content" do
      let(:metadata) do
        {
          "pcdm_use" => "Primary Content"
        }
      end
      it "maps pcdm_use to FileSet:PRIMARY" do
        expect(mapper.pcdm_use).to eq(FileSet::PRIMARY)
      end
    end
    context "supplemental" do
      let(:metadata) do
        {
          "pcdm_use" => "supplemental Content"
        }
      end
      it "maps pcdm_use to FileSet::SUPPLEMENTAL" do
        expect(mapper.pcdm_use).to eq(FileSet::SUPPLEMENTAL)
      end
    end
    context "supplemental preservation" do
      let(:metadata) do
        {
          "pcdm_use" => "Supplemental preservation"
        }
      end
      it "maps pcdm_use to FileSet::PRESERVATION" do
        expect(mapper.pcdm_use).to eq(FileSet::PRESERVATION)
      end
    end

    context "nil" do
      it "maps pcdm_use to primary content" do
        expect(mapper.pcdm_use).to eq(FileSet::PRIMARY)
      end
    end

    context "empty string" do
      let(:metadata) do
        {
          "pcdm_use" => ""
        }
      end
      it "maps pcdm_use to primary content" do
        expect(mapper.pcdm_use).to eq(FileSet::PRIMARY)
      end
    end
  end

  context "#primary_language" do
    it "maps the primary_language field" do
      expect(mapper.primary_language).to eq "English"
    end
  end

  context "#primary_repository_ID" do
    it "maps the primary_repository_ID field" do
      expect(mapper.primary_repository_ID).to eq "1"
    end
  end

  context "#publisher" do
    it "maps the publisher field" do
      expect(mapper.publisher).to eq "Gutenberg"
    end
  end

  context "#related_datasets" do
    it "maps the related_datasets field" do
      expect(mapper.related_datasets).to contain_exactly "Dope Books"
    end
  end

  context "#related_publications" do
    it "maps the related_publications field" do
      expect(mapper.related_publications).to contain_exactly "The Bible", "Dianetics"
    end
  end

  context "#re_use_license" do
    it "maps the re_use_license field" do
      expect(mapper.re_use_license).to contain_exactly "https://creativecommons.org/licenses/by/4.0/"
    end

    context "invalid re_use_license" do
      let(:metadata) do
        {
          "re_use_license" => "https://creativecommons.org/licenses/by/3.0/"
        }
      end
      it "raises an exception when it isn't valid" do
        expect { mapper.re_use_license }.to raise_error RuntimeError
      end
    end

    context "inactive re_use_license" do
      let(:metadata) do
        {
          "re_use_license" => "http://creativecommons.org/licenses/by-nc/3.0/us/"
        }
      end
      it "raises an exception when it isn't valid" do
        expect { mapper.re_use_license }.to raise_error RuntimeError
      end
    end
  end

  context "#rights_documentation" do
    it "maps the rights_documentation field" do
      expect(mapper.rights_documentation).to eq "rights@aol.com"
    end
  end

  context "#rights_holders" do
    it "maps the rights_holders field" do
      expect(mapper.rights_holders).to eq ["Unknown"]
    end
  end

  context "#emory_rights_statements" do
    it "maps the emory_rights_statements field" do
      expect(mapper.emory_rights_statements)
        .to contain_exactly("Emory University does not control copyright for this image.")
    end
  end

  context "#rights_statement" do
    it "maps the rights_statement field when it's valid" do
      expect(mapper.rights_statement).to eq ["http://rightsstatements.org/vocab/InC/1.0/"]
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

  context "#scheduled_rights_review" do
    it "maps the scheduled_rights_review field" do
      expect(mapper.scheduled_rights_review).to eq "2021-01-02"
    end
  end

  context "#scheduled_rights_review_note" do
    it "maps the scheduled_rights_review_note field" do
      expect(mapper.scheduled_rights_review_note).to eq "Rip it off the site."
    end
  end

  context "#sensitive_material" do
    let(:metadata) do
      {
        "title" => "my title",
        "sensitive_material" => "No"
      }
    end
    it "maps the sensitive_material field to what the QA authority expects" do
      expect(mapper.sensitive_material).to eq "false"
    end
  end

  context "#sensitive_material_note" do
    let(:metadata) do
      {
        "title" => "my title",
        "sensitive_material_note" => "Be very careful with this sensitive material."
      }
    end
    it "maps the sensitive_material_note field" do
      expect(mapper.sensitive_material_note).to eq "Be very careful with this sensitive material."
    end
  end

  context "#series_title" do
    it "maps the series_title field" do
      expect(mapper.series_title).to eq "Chatterbox library."
    end
  end

  context "#sponsor" do
    it "maps the sponsor field" do
      expect(mapper.sponsor).to eq "Shell Oil"
    end
  end

  context "#staff_notes" do
    it "maps the staff_notes field" do
      expect(mapper.staff_notes).to contain_exactly "Got this one done."
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

  context "#subject_time_periods" do
    it "maps the subject_time_periods field" do
      expect(mapper.subject_time_periods)
        .to contain_exactly("Medieval Times")
    end
  end

  context "#subject_topics" do
    it "maps the subject_topics field" do
      expect(mapper.subject_topics)
        .to contain_exactly("Snowblowers.", "Snow.", "Air bases.", "Towers.")
    end
  end

  context "#sublocation" do
    let(:metadata) do
      {
        "title" => "my title",
        "sublocation" => "Box 1"
      }
    end
    it "maps the sublocation field" do
      expect(mapper.sublocation).to eq "Box 1"
    end
  end

  context "#system_of_record_ID" do
    it "maps the system_of_record_ID field" do
      expect(mapper.system_of_record_ID).to eq "990020982660302486"
    end
  end

  context "#table_of_contents" do
    it "maps the table_of_contents field" do
      expect(mapper.table_of_contents)
        .to eq "Thing 1. Thing 2."
    end
  end

  context "#technical_note" do
    it "maps the technical_note field" do
      expect(mapper.technical_note).to eq "Use a Mac."
    end
  end

  context "#title" do
    it "maps the required title field" do
      expect(mapper.map_field(:title))
        .to contain_exactly("what an awesome title")
    end
  end

  context "#transfer_engineer" do
    let(:metadata) do
      {
        "title" => "my title",
        "transfer_engineer" => "Leroy Jenkins"
      }
    end
    it "maps the transfer_engineer field" do
      expect(mapper.transfer_engineer).to eq "Leroy Jenkins"
    end
  end

  context "#uniform_title" do
    it "maps the uniform_title field" do
      expect(mapper.uniform_title)
        .to eq "Pittsburg courier."
    end
  end

  context "#volume" do
    it "maps the volume field" do
      expect(mapper.volume).to eq "10"
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
