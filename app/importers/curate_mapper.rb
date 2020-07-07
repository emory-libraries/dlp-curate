# frozen_string_literal: true

class CurateMapper < Zizia::HashMapper
  attr_reader :row_number

  CURATE_TERMS_MAP = {
    abstract:                     "abstract",
    access_restriction_notes:     "access_restriction_notes",
    administrative_unit:          "administrative_unit",
    author_notes:                 "author_notes",
    conference_dates:             "conference_dates",
    conference_name:              "conference_name",
    content_genres:               "content_genres",
    contact_information:          "contact_information",
    content_type:                 "content_type",
    contributors:                 "contributors",
    copyright_date:               "copyright_date",
    creator:                      "creator",
    data_classifications:         "data_classifications",
    data_collection_dates:        "data_collection_dates",
    data_producers:               "data_producers",
    data_source_notes:            "data_source_notes",
    date_created:                 "date_created",
    date_digitized:               "date_digitized",
    date_issued:                  "date_issued",
    deduplication_key:            "deduplication_key",
    edition:                      "edition",
    final_published_versions:     "final_published_versions",
    extent:                       "extent",
    geographic_unit:              "geographic_unit",
    grant_agencies:               "grant_agencies",
    grant_information:            "grant_information",
    holding_repository:           "holding_repository",
    institution:                  "institution",
    internal_rights_note:         "internal_rights_note",
    isbn:                         "isbn",
    issn:                         "issn",
    issue:                        "issue",
    keywords:                     "keywords",
    emory_ark:                    "emory_ark",
    other_identifiers:            "other_identifiers",
    legacy_rights:                "legacy_rights",
    local_call_number:            "local_call_number",
    notes:                        "notes",
    page_range_end:               "page_range_end",
    page_range_start:             "page_range_start",
    parent_title:                 "parent_title",
    pcdm_use:                     "pcdm_use",
    place_of_production:          "place_of_production",
    primary_language:             "primary_language",
    primary_repository_ID:        "primary_repository_ID",
    publisher:                    "publisher",
    related_datasets:             "related_datasets",
    related_material_notes:       "related_material_notes",
    related_publications:         "related_publications",
    re_use_license:               "re_use_license",
    rights_documentation:         "rights_documentation",
    rights_holders:               "rights_holders",
    rights_statement:             "rights_statement",
    emory_rights_statements:      "emory_rights_statements",
    scheduled_rights_review:      "scheduled_rights_review",
    scheduled_rights_review_note: "scheduled_rights_review_note",
    sensitive_material:           "sensitive_material",
    sensitive_material_note:      "sensitive_material_note",
    series_title:                 "series_title",
    sponsor:                      "sponsor",
    staff_notes:                  "staff_notes",
    subject_geo:                  "subject_geo",
    subject_names:                "subject_names",
    subject_time_periods:         "subject_time_periods",
    subject_topics:               "subject_topics",
    sublocation:                  "sublocation",
    system_of_record_ID:          "system_of_record_ID",
    table_of_contents:            "table_of_contents",
    technical_note:               "technical_note",
    title:                        "title",
    transfer_engineer:            "transfer_engineer",
    uniform_title:                "uniform_title",
    volume:                       "volume",
    visibility:                   "visibility"
  }.freeze

  DELIMITER = '|'

  def initialize(attributes = {})
    @row_number = attributes[:row_number]
    super()
  end

  # What columns are allowed in the CSV
  def self.allowed_headers
    CURATE_TERMS_MAP.values + ['type', 'intermediate_file', 'fileset_label', 'preservation_master_file', 'service_file', 'extracted', 'transcript_file', 'pcdm_use']
  end

  # Given a field name, return the CSV header
  def self.csv_header(field)
    CURATE_TERMS_MAP[field.to_sym]
  end

  def fields
    # The fields common to all object types
    common_fields = CURATE_TERMS_MAP.keys
    common_fields
  end

  def files
    []
  end

  # Samvera generally assumes that all fields are multi-valued. Curate, however,
  # has many fields that are defined to be singular. This method returns the array
  # of single-value fields for an easy way to check whether a field is single-valued
  # or multi-valued when mapping it.
  def singular_fields
    work = CurateGenericWork.new
    properties = work.send(:properties)
    properties.select { |_k, v| v.respond_to? :multiple? }.select { |_k, v| !v.multiple? }.keys
  end

  # Match a visibility string to the value below; default to restricted
  def visibility
    value_from_csv = metadata['visibility']&.squish&.downcase
    visibility_mapping.fetch(value_from_csv, Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE)
  end

  # The visibility values have different values when
  # they are calculated or indexed in solr than the
  # values that appear in the UI edit form.  We should
  # accept both.
  def visibility_mapping
    {
      'private' => Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE,
      'restricted' => Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE,
      'authenticated' => Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED,
      'registered' => Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED,
      'emory' => Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED,
      'emory network' => Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED,
      'open' => Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC,
      'public' => Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC,
      'public low view' => Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LOW_RES,
      'emory low download' => Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMORY_LOW,
      'rose high view' => Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_ROSE_HIGH
    }.freeze
  end

  # Return the title if there is one. Otherwise, set it to a placeholder value.
  # We will sometimes have CSV rows that contain only a Filename, but no metadata.
  def title
    value = @metadata["title"] || "Unknown Title"
    Array.wrap(value)
  end

  # Normalize the value coming in because there are subtle mis-matches against the expected controlled
  # vocabulary term. E.g.,
  # "Stuart A. Rose Manuscript, Archives and Rare Book Library" vs
  # "Stuart A. Rose Manuscript, Archives, and Rare Book Library"
  def administrative_unit
    csv_term = @metadata["administrative_unit"]
    return nil unless csv_term
    normalized_csv_term = csv_term.downcase.gsub(/[^a-z0-9\s]/i, '')
    active_terms = Qa::Authorities::Local.subauthority_for('administrative_unit').all.select { |term| term[:active] }
    valid_option = active_terms.select { |s| s["id"].downcase.gsub(/[^a-z0-9\s]/i, '') == normalized_csv_term }.try(:first)
    return valid_option["id"] if valid_option
    raise "Invalid administrative_unit value: #{csv_term}"
  end

  # Map pcdm_use to the values on FileSet
  # Set FileSet::Primary when the value is blank
  def pcdm_use
    csv_term = metadata["pcdm_use"]
    normalized_csv_term = csv_term&.downcase&.gsub(/[^a-z0-9\s]/i, '')
    valid_option = pcdm_value(normalized_csv_term)
    valid_option
  end

  def pcdm_value(normalized_csv_term)
    case normalized_csv_term
    when nil
      FileSet::PRIMARY
    when ''
      FileSet::PRIMARY
    when 'primary content'
      FileSet::PRIMARY
    when 'supplemental content'
      FileSet::SUPPLEMENTAL
    when 'supplemental preservation'
      FileSet::PRESERVATION
    end
  end

  # Iterate through all values for data_classifications and ensure they are all
  # valid options according to Questioning Authority
  def data_classifications
    return nil unless @metadata["data_classifications"]
    csv_terms = @metadata["data_classifications"]&.split(DELIMITER)
    active_terms = Qa::Authorities::Local.subauthority_for('data_classifications').all.select { |term| term[:active] }
    data_classification_values = []
    csv_terms.each do |c|
      valid_option = active_terms.select { |s| s["id"] == c }.try(:first)
      raise "Invalid data_classification value: #{c}" unless valid_option
      data_classification_values << valid_option["id"]
    end
    data_classification_values
  end

  def rights_statement
    return nil unless @metadata["rights_statement"]
    active_terms = Qa::Authorities::Local.subauthority_for('rights_statements').all.select { |term| term[:active] }
    csv_term = @metadata["rights_statement"]
    valid_uri_option = active_terms.select { |s| s["id"] == csv_term }.try(:first)
    return [csv_term] if valid_uri_option
    raise "Invalid rights_statement value: #{csv_term}"
  end

  def truthy?(term)
    return true if term.downcase.strip == "yes"
    return true if term.downcase.strip == "true"
    false
  end

  def falsey?(term)
    return true if term.downcase.strip == "no"
    return true if term.downcase.strip == "false"
    false
  end

  def sensitive_material
    csv_term = @metadata["sensitive_material"]
    return nil unless csv_term
    active_terms = Qa::Authorities::Local.subauthority_for('sensitive_material').all.select { |term| term[:active] }
    transformed_term = false if falsey?(csv_term)
    transformed_term = true if truthy?(csv_term)
    valid_option = active_terms.select { |s| s["id"] == transformed_term }.try(:first)
    return transformed_term.to_s if valid_option
    raise "Invalid sensitive_material value: #{csv_term}"
  end

  # If we get a URI for content_type, check that it matches a URI in the questioning
  # authority config, and return it if so.
  # If we get a string for contenttype, (e.g., 'still image'), transform it into its
  # corresponding Questioning Authority controlled vocabulary uri.
  def content_type
    csv_term = @metadata["content_type"]
    return unless csv_term
    active_terms = Qa::Authorities::Local.subauthority_for('resource_types').all.select { |term| term[:active] }

    # Check whether this is a uri that matches a valid URI option
    valid_uri_option = active_terms.select { |s| s["id"] == csv_term }.try(:first)
    return valid_uri_option["id"] if valid_uri_option && valid_uri_option["id"]
    # Check whether this is a string that can be easily matched to a valid URI
    matching_term = active_terms.find { |s| s["label"].downcase.strip == csv_term.downcase.strip }
    raise "Invalid resource_type value: #{csv_term}" unless matching_term
    matching_term["id"]
  end

  def map_field(name)
    return unless CURATE_TERMS_MAP.keys.include?(name)
    return @metadata[name.to_s] if singular_fields.include?(name.to_s)

    Array.wrap(CURATE_TERMS_MAP[name]).map do |source_field|
      metadata[source_field]&.split(DELIMITER)
    end.flatten.compact
  end

  def re_use_license
    return nil unless @metadata["re_use_license"]
    active_terms = Qa::Authorities::Local.subauthority_for('licenses').all.select { |term| term[:active] }
    csv_term = @metadata["re_use_license"]
    valid_uri_option = active_terms.select { |s| s["id"] == csv_term }.try(:first)
    return [csv_term] if valid_uri_option
    raise "Invalid rights_statement value: #{csv_term}"
  end
end
