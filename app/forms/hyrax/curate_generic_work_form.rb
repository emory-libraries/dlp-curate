# frozen_string_literal: true
module Hyrax
  # Generated form for CurateGenericWork
  class CurateGenericWorkForm < Hyrax::Forms::WorkForm
    include SingleValuedForm
    self.model_class = ::CurateGenericWork
    self.terms = [:title, :institution, :holding_repository, :administrative_unit, :sublocation,
                  :content_type, :content_genre, :abstract, :table_of_contents, :edition,
                  :primary_language, :subject_topics, :subject_names, :subject_geo, :subject_time_periods,
                  :conference_name, :uniform_title, :series_title, :parent_title, :contact_information,
                  :publisher_version, :creator, :contributor, :sponsor, :data_producer, :grant, :grant_information,
                  :author_notes, :note, :data_source_note, :geographic_unit, :technical_note, :issn, :isbn,
                  :related_publications, :related_datasets, :extent, :publisher, :date_created, :date_issued,
                  :conference_dates, :data_collection_dates, :local_call_number, :related_material, :final_published_version,
                  :issue, :page_range_start, :page_range_end, :volume, :place_of_production, :keywords, :rights_statement_text,
                  :rights_statement, :rights_holder, :copyright_date, :re_use_license, :access_right, :rights_documentation,
                  :scheduled_rights_review, :scheduled_rights_review_note, :internal_rights_note, :legacy_rights,
                  :data_classification, :sensitive_material, :sensitive_material_note, :staff_note, :date_digitized,
                  :transfer_engineer, :legacy_identifier, :legacy_ark, :system_of_record_ID, :primary_repository_ID]

    self.required_fields = [:title, :holding_repository, :content_type, :rights_statement_text, :rights_statement,
                            :data_classification, :date_created]
    # TODO: All single-valued fields should be configured this way.
    self.single_valued_fields = [:title]

    def primary_descriptive_metadata_fields
      [:title, :holding_repository, :date_created, :content_type, :content_genre, :administrative_unit, :creator, :contributor,
       :abstract, :primary_language, :date_issued, :extent, :sublocation]
    end

    def secondary_descriptive_metadata_fields
      [:institution, :table_of_contents, :local_call_number, :keywords, :subject_topics, :subject_names, :subject_geo,
       :geographic_unit, :subject_time_periods, :data_collection_dates, :note, :parent_title, :uniform_title, :series_title,
       :related_publications, :related_datasets, :related_material, :publisher, :final_published_version, :publisher_version,
       :issue, :page_range_start, :page_range_end, :volume, :edition, :place_of_production, :issn, :isbn, :conference_dates,
       :conference_name, :sponsor, :data_producer, :grant, :grant_information, :author_notes, :data_source_note, :technical_note]
    end

    def primary_rights_metadata_fields
      [:rights_statement_text, :rights_statement, :data_classification, :rights_holder, :copyright_date, :re_use_license, :access_right,
       :rights_documentation, :sensitive_material, :sensitive_material_note, :scheduled_rights_review, :scheduled_rights_review_note,
       :internal_rights_note, :legacy_rights, :contact_information]
    end

    def primary_admin_metadata_fields
      [:staff_note, :system_of_record_ID, :legacy_identifier, :legacy_ark, :date_digitized, :transfer_engineer]
    end

    def self.build_permitted_params
      permitted = super
      permitted += [:representative_id,
                    :thumbnail_id,
                    :admin_set_id,
                    :visibility_during_embargo,
                    :embargo_release_date,
                    :visibility_after_embargo,
                    :visibility_during_lease,
                    :lease_expiration_date,
                    :visibility_after_lease,
                    :visibility]
      permitted
    end
  end
end
