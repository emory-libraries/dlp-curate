# frozen_string_literal: true

class CurateMapper < Zizia::HashMapper
  attr_reader :row_number

  CURATE_TERMS_MAP = {
    administrative_unit: "administrative_unit",
    content_type: "content_type",
    data_classification: "data_classification",
    date_created: "date_created",
    rights_statement_text: "rights_statement_text",
    rights_statement: "rights_statement",
    title: "title",
    visibility: "visibility"
  }.freeze

  DELIMITER = '|'

  def initialize(attributes = {})
    @row_number = attributes[:row_number]
    super()
  end

  # What columns are allowed in the CSV
  def self.allowed_headers
    CURATE_TERMS_MAP.values
  end

  def fields
    # The fields common to all object types
    common_fields = CURATE_TERMS_MAP.keys
    common_fields
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
      'public' => Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    }.freeze
  end

  # Normalize the value coming in because there are subtle mis-matches against the expected controlled
  # vocabulary term. E.g.,
  # "Stuart A. Rose Manuscript, Archives and Rare Book Library" vs
  # "Stuart A. Rose Manuscript, Archives, and Rare Book Library"
  def administrative_unit
    active_terms = Qa::Authorities::Local.subauthority_for('administrative_unit').all.select { |term| term[:active] }
    csv_term = @metadata["administrative_unit"]
    normalized_csv_term = csv_term.downcase.gsub(/[^a-z0-9\s]/i, '')
    valid_option = active_terms.select { |s| s["id"].downcase.gsub(/[^a-z0-9\s]/i, '') == normalized_csv_term }.try(:first)
    return valid_option["id"] if valid_option
    raise "Invalid administrative_unit value: #{csv_term}"
  end

  # Iterate through all values for data_classification and ensure they are all
  # valid options according to Questioning Authority
  def data_classification
    csv_terms = @metadata["data_classification"]&.split(DELIMITER)
    active_terms = Qa::Authorities::Local.subauthority_for('data_classification').all.select { |term| term[:active] }
    data_classification_values = []
    csv_terms.each do |c|
      valid_option = active_terms.select { |s| s["id"] == c }.try(:first)
      raise "Invalid data_classification value: #{c}" unless valid_option
      data_classification_values << valid_option["id"]
    end
    data_classification_values
  end

  def rights_statement
    active_terms = Qa::Authorities::Local.subauthority_for('rights_statements').all.select { |term| term[:active] }
    csv_term = @metadata["rights_statement"]
    valid_uri_option = active_terms.select { |s| s["id"] == csv_term }.try(:first)
    return csv_term if valid_uri_option
    raise "Invalid rights_statement value: #{csv_term}"
  end

  # If we get a URI for content_type, check that it matches a URI in the questioning
  # authority config, and return it if so.
  # If we get a string for content_type, (e.g., 'still image'), transform it into its
  # corresponding Questioning Authority controlled vocabulary uri.
  def content_type
    active_terms = Qa::Authorities::Local.subauthority_for('resource_types').all.select { |term| term[:active] }
    csv_term = @metadata["content_type"]
    # Check whether this is a uri that matches a valid URI option
    valid_uri_option = active_terms.select { |s| s["id"] == csv_term }.try(:first)
    return csv_term if valid_uri_option
    # Check whether this is a string that can be easily matched to a valid URI
    matching_term = active_terms.select { |s| s["label"].downcase.strip == csv_term.downcase.strip }.first
    raise "Invalid resource_type value: #{csv_term}" unless matching_term
    matching_term["id"]
  end

  def singular_fields
    ["date_created"]
  end

  def map_field(name)
    return unless CURATE_TERMS_MAP.keys.include?(name)
    return @metadata[name.to_s] if singular_fields.include?(name.to_s)

    Array.wrap(CURATE_TERMS_MAP[name]).map do |source_field|
      metadata[source_field]&.split(DELIMITER)
    end.flatten.compact
  end
end
