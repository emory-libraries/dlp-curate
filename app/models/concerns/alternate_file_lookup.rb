# frozen_string_literal: true

module AlternateFileLookup
  extend ActiveSupport::Concern

  def preservation_master_file_by_logic
    return files.first if files.size == 1
    return process_pmf_by_logic_test if label.present?
  end

  def intermediate_file_by_logic
    files.select do |f|
      files.size > 1 && right_file_extensions(f) && label.present? && file_name_not_label(f) && file_name_is_prod(f)
    end&.first
  end

  def extracted_file_by_logic
    files.select do |f|
      files.size > 1 && f&.file_name&.first&.include?('.xml') || f&.file_name&.first&.include?('.pos')
    end&.first
  end

  def transcript_file_by_logic
    files.select { |f| files.size > 1 && f&.file_name&.first&.include?('.txt') }&.first
  end

  def pulled_preservation_master_file
    @pulled_preservation_master_file ||= preservation_master_file&.id&.present? ? preservation_master_file : preservation_master_file_by_logic
  end

  def pulled_service_file
    service_file
  end

  def pulled_intermediate_file
    @pulled_intermediate_file ||= intermediate_file&.id&.present? ? intermediate_file : intermediate_file_by_logic
  end

  def pulled_extracted_file
    @pulled_extracted_file ||= extracted&.id&.present? ? extracted : extracted_file_by_logic
  end

  def pulled_transcript_file
    @pulled_transcript_file ||= transcript_file&.id&.present? ? transcript_file : transcript_file_by_logic
  end

  private

    def process_pmf_by_logic_test
      files.select { |f| f&.file_path&.first&.include?('preservation_master_file') || f&.file_name&.first&.include?('_ARCH') }&.first
    end

    def right_file_extensions(file)
      ['.xml', '.pos', '.txt'].all? { |ext| !file&.file_name&.first&.include?(ext) }
    end

    def file_name_not_label(file)
      !file&.file_name&.first&.include?(label)
    end

    def file_name_is_prod(file)
      file&.file_name&.first&.include?('_PROD')
    end
end
