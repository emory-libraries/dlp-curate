# frozen_string_literal: true

module CsvMatcherBehavior
  GENERAL_PARSE_FIELDS = [
    'remote_files', 'language', 'subject', 'types', 'model', 'resource_type',
    'format_original', 'title', 'content_type', 'rights_statement', 'data_classifications',
    'visibility', 'pcdm_use', 'administrative_unit', 'publisher_version', 're_use_license',
    'sensitive_material'
  ].freeze
  FILE_SET_PARSE_FIELDS = [
    'remote_files', 'language', 'subject', 'types', 'model', 'resource_type',
    'format_original', 'title', 'rights_statement', 'pcdm_use'
  ].freeze

  def validate_qa_for(src, subauthority)
    return if src&.strip&.empty?
    valid_option = pull_valid_option(src, pull_active_terms_for(subauthority))

    return src if valid_option
    raise "Invalid #{subauthority} value: #{src}"
  end

  def pull_valid_option(src, active_terms)
    active_terms&.select { |s| s["id"] == src }&.try(:first)
  end

  def pull_active_terms_for(subauthority)
    Qa::Authorities::Local.subauthority_for(subauthority).all.select { |term| term[:active] }
  end

  def pull_matching_term(src, active_terms)
    # Check whether this is a string that can be easily matched to a valid URI
    matching_term = active_terms.find { |s| s["label"].downcase.strip == src.downcase.strip }

    raise "Invalid resource_type value: #{src}" unless matching_term
    matching_term["id"]
  end

  def normalize_term(term)
    term&.downcase&.gsub(/[^a-z0-9\s]/i, '')
  end

  def pull_transformed_term(term)
    return false if CurateMapper.new.falsey?(term)
    return true if CurateMapper.new.truthy?(term)
    false
  end

  def result_nil_rules(content)
    excluded == true || Bulkrax.reserved_properties.include?(to) ||
      check_if_size || check_if_content(content)
  end

  def check_if_size
    self.if && (!self.if.is_a?(Array) && self.if.length != 2)
  end

  def check_if_content(content)
    self.if && !content.send(self.if[0], Regexp.new(self.if[1]))
  end

  def assign_result
    @result = @result[0] if @result.is_a?(Array) && @result.size == 1
  end

  def choose_parsing_fields(parser)
    if parser.class == Bulkrax::CsvFileSetEntry
      process_parse(FILE_SET_PARSE_FIELDS)
    else
      process_parse(GENERAL_PARSE_FIELDS)
    end
  end
end
