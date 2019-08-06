# frozen_string_literal: true

class CurateMapper < Zizia::HashMapper
  attr_reader :row_number

  CURATE_TERMS_MAP = {
    title: "Desc - Title"
  }.freeze

  DELIMITER = '|~|'

  def initialize(attributes = {})
    @row_number = attributes[:row_number]
    super()
  end

  # What columns are allowed in the CSV
  def self.allowed_headers
    CURATE_TERMS_MAP.values +
      ['Visibility']
  end

  def fields
    # The fields common to all object types
    common_fields = CURATE_TERMS_MAP.keys + [:visibility]
    common_fields
  end
  #
  # def visibility
  #   value_from_csv = metadata['Visibility']&.squish&.downcase
  #   visibility_mapping.fetch(value_from_csv, Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC)
  # end

  # The visibility values have different values when
  # they are calculated or indexed in solr than the
  # values that appear in the UI edit form.  We should
  # accept both.
  def visibility_mapping
    {
      'private' => Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE,
      'restricted' => Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE,
      'discovery' => ::Work::VISIBILITY_TEXT_VALUE_DISCOVERY,
      'authenticated' => Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED,
      'registered' => Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED,
      'ucla' => Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED,
      'open' => Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC,
      'public' => Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    }.freeze
  end

  def map_field(name)
    return unless CURATE_TERMS_MAP.keys.include?(name)

    Array.wrap(CURATE_TERMS_MAP[name]).map do |source_field|
      metadata[source_field]&.split(DELIMITER)
    end.flatten.compact
  end
end
