# frozen_string_literal: true

class CurateMapper < Zizia::HashMapper
  attr_reader :row_number

  CURATE_TERMS_MAP = {
    title: "title",
    content_type: "content_type",
    visibility: "visibility"
  }.freeze

  DELIMITER = '|~|'

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
      'open' => Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC,
      'public' => Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    }.freeze
  end

  # Translate a content_type string in the CSV (e.g., 'still image') into its
  # corresponding controlled vocabulary uri as defined by Questioning Authority
  def content_type
    active_terms = Qa::Authorities::Local.subauthority_for('resource_types').all.select { |term| term[:active] }
    csv_term = @metadata["content_type"]
    matching_term = active_terms.select { |s| s["label"].downcase.strip == csv_term.downcase.strip }.first
    raise "Invalid resource_type value: #{csv_term}" unless matching_term
    matching_term["id"]
  end

  def map_field(name)
    return unless CURATE_TERMS_MAP.keys.include?(name)

    Array.wrap(CURATE_TERMS_MAP[name]).map do |source_field|
      metadata[source_field]&.split(DELIMITER)
    end.flatten.compact
  end
end
