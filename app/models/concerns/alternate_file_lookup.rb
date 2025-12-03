# frozen_string_literal: true

module AlternateFileLookup
  extend ActiveSupport::Concern

  def preservation_master_file_by_logic
    if files.size == 1
      files.first
    elsif label.present?
      files.select { |f| f&.file_path&.first&.include?('preservation_master_file') || f&.file_name&.first&.include?('_ARCH') }&.first
    end
  end

  def intermediate_file_by_logic
    files.select do |f|
      files.size > 1 &&
        ['.xml', '.pos', '.txt'].all? { |ext| !f&.file_name&.first&.include?(ext) } &&
        label.present? &&
        !f&.file_name&.first&.include?(label) &&
        f&.file_name&.first&.include?('_PROD')
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
    @pulled_preservation_master_file ||= preservation_master_file&.file_name&.present? ? preservation_master_file : preservation_master_file_by_logic
  end

  def pulled_intermediate_file
    @pulled_intermediate_file ||= intermediate_file&.file_name&.present? ? intermediate_file : intermediate_file_by_logic
  end

  def pulled_extracted_file
    @pulled_extracted_file ||= extracted&.file_name&.present? ? extracted : extracted_file_by_logic
  end

  def pulled_transcript_file
    @pulled_transcript_file ||= transcript_file&.file_name&.present? ? transcript_file : transcript_file_by_logic
  end
end
