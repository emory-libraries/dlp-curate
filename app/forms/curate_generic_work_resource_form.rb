# frozen_string_literal: true

# Valkyrie form for CurateGenericWorkResource.
# Mirrors field groupings from the AF Hyrax::CurateGenericWorkForm.
class CurateGenericWorkResourceForm < Hyrax::Forms::PcdmObjectForm(CurateGenericWorkResource)
  include Hyrax::FormFields(:emory_basic_metadata)
  include Hyrax::FormFields(:curate_generic_work_resource)

  def primary_descriptive_metadata_fields
    [:title, :holding_repository, :date_created, :content_type, :content_genres,
     :administrative_unit, :creator, :contributors, :abstract, :primary_language,
     :date_issued, :extent, :sublocation]
  end

  def secondary_descriptive_metadata_fields
    [:institution, :table_of_contents, :local_call_number, :keywords, :subject_topics,
     :subject_names, :subject_geo, :geographic_unit, :subject_time_periods, :data_collection_dates,
     :notes, :parent_title, :uniform_title, :series_title, :related_publications,
     :related_datasets, :related_material_notes, :publisher, :final_published_versions,
     :publisher_version, :issue, :page_range_start, :page_range_end, :volume, :edition,
     :place_of_production, :issn, :isbn, :conference_dates, :conference_name, :sponsor,
     :data_producers, :grant_agencies, :grant_information, :author_notes, :data_source_notes,
     :technical_note]
  end

  def primary_rights_metadata_fields
    [:emory_rights_statements, :rights_statement, :data_classifications, :rights_holders,
     :copyright_date, :re_use_license, :access_restriction_notes, :rights_documentation,
     :sensitive_material, :sensitive_material_note, :scheduled_rights_review, :scheduled_rights_review_note,
     :internal_rights_note, :legacy_rights, :contact_information]
  end

  def primary_admin_metadata_fields
    [:staff_notes, :system_of_record_ID, :other_identifiers, :emory_ark, :date_digitized,
     :transfer_engineer, :deduplication_key, :source_collection_id]
  end
end
