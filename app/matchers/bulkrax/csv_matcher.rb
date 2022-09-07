# frozen_string_literal: true

module Bulkrax
  class CsvMatcher < ApplicationMatcher
    GENERAL_PARSE_FIELDS = [
      'remote_files', 'language', 'subject', 'types', 'model', 'resource_type',
      'format_original', 'content_type', 'rights_statement', 'data_classifications',
      'visibility', 'pcdm_use', 'administrative_unit'
    ].freeze
    FILE_SET_PARSE_FIELDS = [
      'remote_files', 'language', 'subject', 'types', 'model', 'resource_type',
      'format_original', 'title', 'rights_statement', 'pcdm_use'
    ].freeze

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

    private

      def validate_qa_for(src, subauthority)
        return unless src
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
  end
end
