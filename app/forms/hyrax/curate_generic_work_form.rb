# Generated via
#  `rails generate hyrax:work CurateGenericWork`
module Hyrax
  # Generated form for CurateGenericWork
  class CurateGenericWorkForm < Hyrax::Forms::WorkForm
    self.model_class = ::CurateGenericWork
    self.terms = [:title, :institution, :holding_repository, :administrative_unit, :sublocation,
                  :content_type, :content_genre, :abstract, :table_of_contents, :edition,
                  :primary_language, :subject_topics, :subject_names, :subject_geo, :subject_time_periods,
                  :conference_name, :uniform_title, :series_title, :parent_title, :contact_information,
                  :publisher_version, :creator, :contributor, :sponsor, :data_producer, :grant, :grant_information,
                  :author_notes, :note, :data_source_note, :geographic_unit, :technical_note, :issn, :isbn,
                  :related_publications, :related_datasets, :extent, :publisher, :date_created, :date_issued,
                  :conference_dates, :data_collection_dates, :local_call_number, :related_material, :final_published_version,
                  :issue, :page_range_start, :page_range_end, :volume, :place_of_production, :keywords, :rights_statement,
                  :rights_statement_controlled, :rights_holder, :copyright_date, :license, :access_right, :rights_documentation,
                  :scheduled_rights_review, :scheduled_rights_review_note, :internal_rights_note, :legacy_rights,
                  :data_classification, :sensitive_material, :sensitive_material_note, :staff_note, :date_digitized,
                  :transfer_engineer, :legacy_identifier, :legacy_ark, :system_of_record_ID, :primary_repository_ID]

    self.required_fields = [:title, :holding_repository, :content_type, :rights_statement, :rights_statement_controlled,
                            :data_classification, :primary_repository_ID]

    def primary_descriptive_metadata_fields
      [:title, :holding_repository, :content_type]
    end

    def secondary_descriptive_metadata_fields
      [:institution, :administrative_unit, :sublocation, :content_genre, :abstract, :table_of_contents,
       :edition, :primary_language, :subject_topics, :subject_names, :subject_geo, :subject_time_periods,
       :conference_name, :uniform_title, :series_title, :parent_title, :contact_information,
       :publisher_version, :creator, :contributor, :sponsor, :data_producer, :grant, :grant_information,
       :author_notes, :note, :data_source_note, :geographic_unit, :technical_note, :issn, :isbn,
       :related_publications, :related_datasets, :extent, :publisher, :date_created, :date_issued,
       :conference_dates, :data_collection_dates, :local_call_number, :related_material, :final_published_version,
       :issue, :page_range_start, :page_range_end, :volume, :place_of_production, :keywords]
    end

    def primary_rights_metadata_fields
      [:rights_statement, :rights_statement_controlled, :data_classification]
    end

    def secondary_rights_metadata_fields
      [:rights_holder, :copyright_date, :access_right, :rights_documentation, :scheduled_rights_review,
       :scheduled_rights_review_note, :internal_rights_note, :legacy_rights, :sensitive_material, :sensitive_material_note]
    end

    def primary_admin_metadata_fields
      [:primary_repository_ID]
    end

    def secondary_admin_metadata_fields
      [:staff_note, :date_digitized, :transfer_engineer, :legacy_identifier, :legacy_ark, :system_of_record_ID]
    end
  end
end
