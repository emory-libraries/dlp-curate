# frozen_string_literal: true

# Valkyrie form for CollectionResource.
# Mirrors field groupings from the AF Hyrax::Forms::CollectionForm.
class CollectionResourceForm < Hyrax::Forms::PcdmCollectionForm
  include Hyrax::FormFields(:emory_basic_metadata)
  include Hyrax::FormFields(:collection_resource)

  def primary_terms
    [:title, :holding_repository, :creator, :abstract]
  end

  def secondary_terms
    [:administrative_unit, :contributors, :primary_language, :finding_aid_link,
     :institution, :local_call_number, :keywords, :subject_topics, :subject_names,
     :subject_geo, :subject_time_periods, :notes, :rights_documentation, :sensitive_material,
     :internal_rights_note, :contact_information, :staff_notes, :system_of_record_ID,
     :emory_ark, :alt_title, :source_collection_id, :deposit_collection_ids]
  end

  def display_additional_fields?
    secondary_terms.any?
  end
end
