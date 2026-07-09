# frozen_string_literal: true
# Bulkrax v8.2.3 override: #filename (AF + Valkyrie dual-path)

module Bulkrax
  module ExportBehavior
    extend ActiveSupport::Concern

    delegate :export_type, :exporter_export_path, to: :importerexporter

    def build_for_exporter
      build_export_metadata
    rescue RSolr::Error::Http, CollectionsCreatedError => e
      raise e
    rescue StandardError => e
      set_status_info(e)
    else
      set_status_info
    end

    def build_export_metadata
      raise StandardError, 'not implemented'
    end

    def hyrax_record
      @hyrax_record ||= Bulkrax.object_factory.find(identifier)
    end

    def filename(file_set)
      if file_set.is_a?(Hyrax::Resource)
        filename_valkyrie(file_set)
      else
        filename_af(file_set)
      end
    end

    def filename_af(file_set)
      uploader_types = ['service_file', 'preservation_master_file', 'intermediate_file',
                        'extracted', 'transcript_file']
      working_array = []
      uploader_types.each do |type|
        begin
          file = file_set.send(type)
        rescue
          file = nil
        end
        next if file.blank?

        file_name = file.respond_to?(:original_filename) ? file.original_filename : file.file_name.first

        working_array << "#{file_name}:extracted_text" if type == 'extracted'
        working_array << "#{file_name}:transcript" if type == 'transcript_file'
        working_array << "#{file_name}:#{type}" unless type == 'extracted' || type == 'transcript_file'
      end
      working_array.compact.join('|')
    end

    def filename_valkyrie(file_set)
      file_metadatas = Hyrax.custom_queries.find_files(file_set:)
      working_array = []
      file_metadatas.each do |fm|
        file_name = Array(fm.original_filename).first || fm.label.to_s
        next if file_name.blank?

        type = valkyrie_file_use_label(fm)
        working_array << "#{file_name}:#{type}"
      end
      working_array.compact.join('|')
    end

    def valkyrie_file_use_label(file_metadata)
      use = Array(file_metadata.pcdm_use).first || Array(file_metadata.type).first.to_s
      case use.to_s
      when /ExtractedText/, /extracted/i
        'extracted_text'
      when /Transcript/, /transcript/i
        'transcript'
      when /ServiceFile/, /service/i
        'service_file'
      when /IntermediateFile/, /intermediate/i
        'intermediate_file'
      else
        'preservation_master_file'
      end
    end
  end
end
