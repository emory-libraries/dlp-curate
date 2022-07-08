# frozen_string_literal: true

module Bulkrax
  class CsvMatcher < ApplicationMatcher
    def process_parse
      # New parse methods will need to be added here
      parsed_fields = [
        'remote_files', 'language', 'subject', 'types', 'model', 'resource_type',
        'format_original', 'content_type', 'rights_statement', 'data_classifications',
        'visibility', 'pcdm_use'
      ]
      # This accounts for prefixed matchers
      parser = parsed_fields.find { |field| to&.include? field }

      if @result.is_a?(Array) && parsed && respond_to?("parse_#{parser}")
        @result.each_with_index do |res, index|
          @result[index] = send("parse_#{parser}", res.strip)
        end
        @result.delete(nil)
      elsif parsed && respond_to?("parse_#{parser}")
        @result = send("parse_#{parser}", @result)
      end
    end

    def parse_title(src)
      src.blank? ? "Unknown Title" : src.strip!
    end

    def parse_content_type(src)
      return unless src
      active_terms = Qa::Authorities::Local.subauthority_for('resource_types').all.select { |term| term[:active] }
      # Check whether this is a uri that matches a valid URI option
      valid_uri_option = active_terms.select { |s| s["id"] == src }.try(:first)

      return valid_uri_option["id"] if valid_uri_option && valid_uri_option["id"]
      # Check whether this is a string that can be easily matched to a valid URI
      matching_term = active_terms.find { |s| s["label"].downcase.strip == src.downcase.strip }

      raise "Invalid resource_type value: #{src}" unless matching_term
      matching_term["id"]
    end

    def parse_rights_statement(src)
      return unless src
      active_terms = Qa::Authorities::Local.subauthority_for('rights_statements').all.select { |term| term[:active] }
      valid_uri_option = active_terms.select { |s| s["id"] == src }.try(:first)

      return src if valid_uri_option
      raise "Invalid rights_statement value: #{src}"
    end

    def parse_data_classifications(src)
      return unless src
      active_terms = Qa::Authorities::Local.subauthority_for('data_classifications').all.select { |term| term[:active] }
      valid_option = active_terms.select { |s| s["id"] == src }.try(:first)

      return src if valid_option
      raise "Invalid data_classification value: #{src}"
    end

    def parse_visibility(src)
      value_from_csv = src&.squish&.downcase
      CurateMapper.new.visibility_mapping.fetch(
        value_from_csv, Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
      )
    end

    def parse_pcdm_use(src)
      normalized_term = src&.downcase&.gsub(/[^a-z0-9\s]/i, '')
      CurateMapper.new.pcdm_value(normalized_term)
    end
  end
end
