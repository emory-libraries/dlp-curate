# frozen_string_literal: true
require 'rails_helper'
include Warden::Test::Helpers

RSpec.describe 'Bulkrax CSV importer', clean: true, js: true, type: :system do
  context 'field mappings' do
    let(:pulled_field_mappings) { Bulkrax.field_mappings['Bulkrax::CsvParser'] }
    let(:all_mapped_fields) do
      ["abstract", "access_restriction_notes", "administrative_unit", "author_notes",
       "conference_dates", "conference_name", "contact_information", "content_genres",
       "content_type", "contributors", "copyright_date", "creator", "data_classifications",
       "data_collection_dates", "data_producers", "data_source_notes", "date_created",
       "date_digitized", "date_issued", "deduplication_key", "edition", "emory_ark",
       "emory_rights_statements", "extent", "file", "file_types", "final_published_versions",
       "geographic_unit", "grant_agencies", "grant_information", "holding_repository",
       "institution", "internal_rights_note", "isbn", "issn", "issue", "keywords",
       "legacy_rights", "local_call_number", "model", "notes", "other_identifiers",
       "page_range_end", "page_range_start", "parent", "parent_title", "pcdm_use",
       "place_of_production", "primary_language", "primary_repository_ID", "publisher",
       "publisher_version", "re_use_license", "related_datasets", "related_material_notes",
       "related_publications", "rights_documentation", "rights_holders", "rights_statement",
       "scheduled_rights_review", "scheduled_rights_review_note", "sensitive_material",
       "sensitive_material_note", "series_title", "source_collection_id", "sponsor",
       "staff_notes", "subject_geo", "subject_names", "subject_time_periods", "subject_topics",
       "sublocation", "system_of_record_ID", "table_of_contents", "technical_note",
       "title", "transfer_engineer", "uniform_title", "visibility", "volume"]
    end
    let(:multiple_value_fields) do
      ["access_restriction_notes", "content_genres", "contributors", "creator", "data_classifications",
       "data_collection_dates", "data_producers", "data_source_notes", "emory_ark",
       "emory_rights_statements", "file", "file_types", "final_published_versions",
       "grant_agencies", "grant_information", "keywords", "notes", "other_identifiers",
       "related_datasets", "related_material_notes", "related_publications", "rights_holders",
       "rights_statement", "staff_notes", "subject_geo", "subject_names", "subject_time_periods",
       "subject_topics", "title"]
    end
    let(:parsed_fields) do
      ["administrative_unit", "content_type", "data_classifications", "pcdm_use",
       "publisher_version", "re_use_license", "rights_statement", "sensitive_material",
       "title", "visibility"]
    end

    it 'maps the expected fields' do
      expect(pulled_field_mappings.keys).to match_array(all_mapped_fields)
    end

    it 'contains the expected multivalue fields' do
      expect(pulled_field_mappings.select { |_k, v| v[:split].present? }.keys).to match_array(multiple_value_fields)
    end

    it 'contains the expected parsed fields' do
      expect(pulled_field_mappings.select { |_k, v| v[:parsed] }.keys).to match_array(parsed_fields)
    end
  end

  context 'not logged in' do
    it 'redirects you to login when visiting dashboard ' do
      visit '/dashboard'
      expect(page.current_path).to include('/sign_in')
    end

    it 'redirects you to login when attempting to create new importer ' do
      visit '/importers/new'
      expect(page.current_path).to include('/sign_in')
    end
  end

  context 'logged in admin user' do
    let(:admin) { FactoryBot.create(:admin) }
    let(:csv_file) { File.join(fixture_path, 'csv_import', 'good', 'Bulkrax_Test_CSV.csv') }

    before do
      login_as admin
      allow_any_instance_of(Ability).to receive(:can_import_works?).and_return(true)
    end

    it 'displays importers on Dashboard' do
      visit '/dashboard'

      expect(page).to have_css('li a span.sidebar-action-text', text: 'Importers')
    end

    context 'within importers/new' do
      before do
        visit '/importers/new'
        select('CSV - Comma Separated Values', from: 'Parser')
      end

      it 'has the expected CSV importer fields' do
        expect(find_all('#importer_parser_fields_visibility option').map(&:text)).to match_array(
          ["Emory High Download", "Emory Low Download", "Private", "Public", "Public Low View",
           "Rose High View"]
        )
      end

      it 'accepts a CSV to upload' do
        page.choose('Upload a File')
        attach_file('importer[parser_fields][file]', csv_file, make_visible: true)
        click_on('Create and Validate')
      end
    end
  end
end
