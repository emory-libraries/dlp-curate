# frozen_string_literal: true

module Bulkrax
  class CsvMatcher < ApplicationMatcher
    include CsvMatcherBehavior

    def result(parser, content)
      return nil if result_nil_rules(content)

      # @result will evaluate to an empty string for nil content values
      @result = content.to_s.gsub(/\s/, ' ').strip # remove any line feeds and tabs
      process_split if @result.present?
      assign_result
      choose_parsing_fields(parser)
      @result
    end

    def process_parse(fields)
      # This accounts for prefixed matchers
      parser = fields.find { |field| to&.include? field }

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
      active_terms = pull_active_terms_for('resource_types')
      # Check whether this is a uri that matches a valid URI option
      valid_uri_option = pull_valid_option(src, active_terms)

      return valid_uri_option["id"] if valid_uri_option && valid_uri_option["id"]
      # Check whether this is a string that can be easily matched to a valid URI
      pull_matching_term(src, active_terms)
    end

    def parse_rights_statement(src)
      validate_qa_for(src, 'rights_statements')
    end

    def parse_data_classifications(src)
      validate_qa_for(src, 'data_classifications')
    end

    def parse_visibility(src)
      value_from_csv = src&.squish&.downcase
      CurateMapper.new.visibility_mapping.fetch(
        value_from_csv, Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
      )
    end

    def parse_pcdm_use(src)
      CurateMapper.new.pcdm_value(normalize_term(src))
    end

    def parse_administrative_unit(src)
      return unless src
      active_terms = pull_active_terms_for('administrative_unit')
      valid_option = active_terms.select do |s|
        s["id"].downcase.gsub(/[^a-z0-9\s]/i, '') == normalize_term(src)
      end.try(:first)

      return valid_option["id"] if valid_option
      raise "Invalid administrative_unit value: #{src}"
    end

    def parse_publisher_version(src)
      return unless src
      terms = Qa::Authorities::Local.subauthority_for('publisher_version').all
      valid_option = pull_valid_option(src, terms)

      return src if valid_option
      raise "Invalid publisher_version value: #{src}"
    end

    def parse_re_use_license(src)
      return unless src
      active_terms = pull_active_terms_for('licenses')
      valid_option = pull_valid_option(src, active_terms)

      return src if valid_option
      raise "Invalid re_use_license value: #{src}"
    end

    def parse_sensitive_material(src)
      return unless src
      active_terms = pull_active_terms_for('sensitive_material')
      transformed_term = pull_transformed_term(src)
      valid_option = pull_valid_option(transformed_term, active_terms)

      return transformed_term.to_s if valid_option
      raise "Invalid sensitive_material value: #{src}"
    end
  end
end
