# frozen_string_literal: true

# Validate a CSV file.
#
# Don't put expensive validations in this class.
# This is meant to be used for running a few quick
# validations before starting a CSV-based import.
# It will be called during the HTTP request/response,
# so long-running validations will make the page load
# slowly for the user.  Any validations that are slow
# should be run in background jobs during the import
# instead of here.
module Zizia
  class CsvManifestValidator
    # @param manifest_uploader [CsvManifestUploader] The manifest that's mounted to a CsvImport record.  See carrierwave gem documentation.  This is basically a wrapper for the CSV file.
    def initialize(manifest_uploader)
      @csv_file = manifest_uploader.file
      @errors = []
      @warnings = []
    end

    # Errors and warnings for the CSV file.
    attr_reader :errors, :warnings
    attr_reader :csv_file

    def validate
      parse_csv
      return unless @rows

      missing_headers
      duplicate_headers
      unrecognized_headers
      missing_values
      # invalid_license # Not yet implemented for Emory
      invalid_resource_type
      # invalid_rights_statement # Not yet implemented for Emory
    end

    # One record per row
    def record_count
      return nil unless @rows
      @rows.size - 1 # Don't include the header row
    end

    def delimiter
      @delimiter ||= default_delimiter
    end
    attr_writer :delimiter

    private

      def default_delimiter
        Zizia::HyraxBasicMetadataMapper.new.delimiter
      end

      def valid_headers
        [
          'Item ID', 'Desc - Abstract',
          'Desc - Administrative Unit',
          'Desc - Call Number/MSS Number',
          'Desc - Collection Name',
          'Desc - Contact Information',
          'Desc - Creator',
          'Desc - Date Created',
          'Desc - Date Published',
          'Desc - Genre - AAT',
          'Desc - Genre - Legacy Data',
          'Desc - Holding Repository',
          'Desc - Institution',
          'Desc - Language - Primary',
          'Desc - Language - Secondary',
          'Desc - Legacy Identifier',
          'Desc - Notes',
          'Desc - PID',
          'Desc - Place of Publication',
          'Desc - Publisher',
          'Desc - Rights Statement',
          'Desc - RightsStatement.org Designation (Label)',
          'Desc - RightsStatement.org Designation (URI)',
          'Desc - Subject - Corporate Name - LCNAF',
          'Desc - Subject - Geographic - LCSH',
          'Desc - Subject - Keywords',
          'Desc - Subject - Meeting Name - LCNAF',
          'Desc - Subject - Personal Name - LCNAF',
          'Desc - Subject - Topic - LCSH',
          'Desc - Subject - Uniform Title - LCNAF',
          'Desc - Table of Contents (Books)',
          'Desc - Title',
          'Desc - Type of Resource',
          'Digital Object - Data Classification',
          'Digital Object - Structure',
          'Digital Object - Viewer Settings',
          'Digital Object - Visibility',
          'Filename'
        ]
      end

      def parse_csv
        @rows = CSV.read(csv_file.path)
        @headers = @rows.first || []
        @transformed_headers = @headers.map { |header| header.downcase.strip }
      rescue
        @errors << 'We are unable to read this CSV file.'
      end

      def missing_headers
        required_headers.each do |header|
          next if @transformed_headers.include?(header.downcase.strip)
          @errors << "Missing required column: #{header.titleize.squeeze(' ')}. Your spreadsheet must have this column. If you already have this column, please check the spelling and capitalization."
        end
      end

      def required_headers
        ['Desc - Title', 'Filename']
      end

      def duplicate_headers
        duplicates = []
        sorted_headers = @transformed_headers.sort
        sorted_headers.each_with_index do |x, i|
          duplicates << x if x == sorted_headers[i + 1]
        end
        duplicates.uniq.each do |header|
          @errors << "Duplicate column names: You can have only one \"#{header.titleize}\" column."
        end
      end

      # Warn the user if we find any unexpected headers.
      def unrecognized_headers
        normalized_valid_headers = valid_headers.map { |a| a.downcase.strip }
        extra_headers = @transformed_headers - normalized_valid_headers
        extra_headers.each do |header|
          @warnings << "The field name \"#{header}\" is not supported.  This field will be ignored, and the metadata for this field will not be imported."
        end
      end

      def transformed_required_headers
        required_headers.map { |a| a.downcase.strip.squeeze(' ') }
      end

      def missing_values
        column_numbers = transformed_required_headers.map { |header| @transformed_headers.find_index(header) }.compact
        @rows.each_with_index do |row, i|
          column_numbers.each_with_index do |column_number, j|
            next unless row[column_number].blank?
            @errors << "Missing required metadata in row #{i + 1}: \"#{required_headers[j].titleize}\" field cannot be blank"
          end
        end
      end

      # Only allow valid license values expected by Hyrax.
      # Otherwise the app throws an error when it displays the work.
      def invalid_license
        validate_values('license', :valid_licenses)
      end

      def invalid_resource_type
        validate_values('Desc - Type of Resource', :valid_resource_types)
      end

      def invalid_rights_statement
        validate_values('rights statement', :valid_rights_statements)
      end

      def valid_licenses
        @valid_license_ids ||= Hyrax::LicenseService.new.authority.all.select { |license| license[:active] }.map { |license| license[:id] }
      end

      # @return Array containing all valid URIs and all valid labels
      def valid_resource_types
        @valid_resource_type_ids ||= Qa::Authorities::Local.subauthority_for('resource_types').all.select { |term| term[:active] }.map { |term| term[:id] }
        @valid_resource_type_labels ||= Qa::Authorities::Local.subauthority_for('resource_types').all.select { |term| term[:active] }.map { |term| term[:label] }
        @valid_resource_type_ids + @valid_resource_type_labels + @valid_resource_type_labels.map { |a| a.downcase.strip.squeeze(' ') }
      end

      def valid_rights_statements
        @valid_rights_statement_ids ||= Qa::Authorities::Local.subauthority_for('rights_statements').all.select { |term| term[:active] }.map { |term| term[:id] }
      end

      # Make sure this column contains only valid values
      def validate_values(header_name, valid_values_method)
        column_number = @transformed_headers.find_index(header_name.downcase.strip.squeeze(' '))
        return unless column_number

        @rows.each_with_index do |row, i|
          next if i.zero? # Skip the header row
          next unless row[column_number]

          values = row[column_number].split(delimiter)
          valid_values = method(valid_values_method).call
          invalid_values = values.select { |value| !valid_values.include?(value) }

          invalid_values.each do |value|
            @errors << "Invalid #{header_name.titleize} in row #{i + 1}: #{value}"
          end
        end
      end
  end
end
