# frozen_string_literal: true

module Curate
  class FileSetIndexer < Hyrax::FileSetIndexer
    def generate_solr_document
      super.tap do |solr_doc|
        solr_doc['is_page_of_ssi'] = object&.parent&.id
        solr_doc['pcdm_use_tesim'] = object.pcdm_use if object.pcdm_use.present?
        solr_doc['file_path_ssim'] = object.file_path if object.file_path.present?
        solr_doc['creating_application_name_ssim'] = object.creating_application_name if object.creating_application_name.present?
        solr_doc['puid_ssim'] = object.puid if object.puid.present?
        solr_doc['preservation_event_tesim'] = [other_events + object&.preservation_event&.map(&:preservation_event_terms)]
        if object.preservation_master_file.present?
          solr_doc['file_name_ssim'] = object.preservation_master_file.file_name
          solr_doc['file_size_ssim'] = object.preservation_master_file.file_size
          solr_doc['date_created_ssim'] = object.preservation_master_file.date_created
          solr_doc['valid_ssim'] = object.preservation_master_file.valid
          solr_doc['well_formed_ssim'] = object.preservation_master_file.well_formed
          solr_doc['character_set_ssim'] = object.preservation_master_file.character_set
          solr_doc['byte_order_ssim'] = object.preservation_master_file.byte_order
          solr_doc['color_space_ssim'] = object.preservation_master_file.color_space
          solr_doc['compression_ssim'] = object.preservation_master_file.compression
          solr_doc['profile_name_ssim'] = object.preservation_master_file.profile_name
          solr_doc['profile_version_ssim'] = object.preservation_master_file.profile_version
        end
        add_sha1(solr_doc)
        solr_doc['page_text_timv'] = page_text_data
        solr_doc['page_text_tsimv'] = page_text_data
      end
    end

    private

      def add_sha1(solr_doc)
        solr_doc['sha1_tesim'] = [object&.preservation_master_file&.checksum&.uri&.to_s,
                                  object&.intermediate_file&.checksum&.uri&.to_s,
                                  object&.service_file&.checksum&.uri&.to_s,
                                  object&.extracted&.checksum&.uri&.to_s,
                                  object&.transcript_file&.checksum&.uri&.to_s]
      end

      # Get all events that appear as nested_objects in fedora
      # but are missing from the preservation_event md field
      def other_events
        result = []
        final_result = []
        # we go through each entry in the file_set resource
        object.resource.each_entry do |e|
          entry_id = e.as_json["subject"]["@id"]
          # we are only interested in entries that are nested and are missing in preservation_event md field
          if entry_id.include?("#nested") && object.preservation_event.none? { |pe| pe.as_json["id"] == entry_id }
            # append it to a result array
            result << [id: entry_id, predicate: e.as_json["predicate"]["@id"], value: e.as_json["object"]["@value"]]
          end
        end
        # once we have all required entries in the result array, we need to group them by their respective IDs
        grouping_by_id = result.group_by { |r| r.first[:id] }
        # once grouped, go through each value from the groupings of IDs
        grouping_by_id.each_value do |grouping|
          event_details = []
          event_type = event_end = event_start = initiating_user = outcome = software_version = ''
          # each grouping/value has a predicate and a value;
          # we go through each grouping and assign values to its respective variable
          # by matching the predicate
          grouping.each do |preservation_event|
            case preservation_event.first[:predicate]
            when "http://metadata.emory.edu/vocab/cor-terms#eventDetails" then event_details << preservation_event_value(preservation_event)
            when "http://metadata.emory.edu/vocab/cor-terms#eventType" then event_type = preservation_event_value(preservation_event)
            when "http://metadata.emory.edu/vocab/cor-terms#eventEnd" then event_end = preservation_event_value(preservation_event)
            when "http://metadata.emory.edu/vocab/cor-terms#eventStart" then event_start = preservation_event_value(preservation_event)
            when "http://metadata.emory.edu/vocab/cor-terms#eventUser" then initiating_user = preservation_event_value(preservation_event)
            when "http://metadata.emory.edu/vocab/cor-terms#eventOutcome" then outcome = preservation_event_value(preservation_event)
            when "http://metadata.emory.edu/vocab/cor-terms#softwareVersion" then software_version = preservation_event_value(preservation_event)
            end
          end
          # once we have all the matching values in their respective variables,
          # we create a hash and append it to an array
          final_result << [
            {
              'event_details' => event_details,
              'event_type' => event_type,
              'event_end' => event_end,
              'event_start' => event_start,
              'initiating_user' => initiating_user,
              'outcome' => outcome,
              'software_version' => software_version
            }.to_json
          ].first
        end
        # we finally return the array with hashes for the missing preservation_events
        final_result
      end

      def preservation_event_value(preservation_event)
        preservation_event.pluck(:value).first
      end

      def page_text_data
        if object.transcript_file.present? && object.transcript_file.content == "[NO TEXT ON PAGE. This page does not contain any text recoverable by the OCR engine.]\n"
          object.transcript_file.content.encode('UTF-8', invalid: :replace, undef: :replace, replace: '')
        end
      end
  end
end
