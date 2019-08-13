# frozen_string_literal: true
module Hyrax
  class CurateCollectionPresenter < Hyrax::CollectionPresenter
    CurateGenericWorkAttributes.instance.attributes.each do |key|
      delegate key.to_sym, to: :solr_document
    end

    delegate :finding_aid_link, to: :solr_document

    # Terms is the list of fields displayed by
    # app/views/collections/_show_descriptions.html.erb
    def self.terms
      [
        :holding_repository,
        :administrative_unit,
        :contributor,
        :abstract,
        :primary_language,
        :finding_aid_link,
        :institution,
        :local_call_number,
        :keywords,
        :subject_topics,
        :subject_names,
        :subject_geo,
        :subject_time_periods,
        :note,
        :rights_documentation,
        :sensitive_material,
        :internal_rights_note,
        :contact_information,
        :staff_note,
        :system_of_record_ID,
        :legacy_ark,
        :primary_repository_ID
      ]
    end
  end
end
