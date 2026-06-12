# frozen_string_literal: true

class CreatePreservationEventJob < Hyrax::ApplicationJob
  include PreservationEvents

  retry_on(Exception) do |job, exception|
    report_completely_failed_creation(job:, exception:) if exception&.message&.present?
  end

  def perform(object:, event:)
    create_preservation_event(object, event)
  end

  private

    def file_path
      "config/emory/failed_preservation_event_creations.csv"
    end

    def csv_exists?
      File.exist?(file_path)
    end

    def pres_event_headers
      ['Job ID', 'Exception', 'Object ID', 'event_details', 'event_end', 'event_start',
       'event_type', 'initiating_user', 'outcome', 'software_version']
    end

    def report_completely_failed_creation(job:, exception:)
      CSV.open(file_path, "a+", write_headers: !csv_exists?, headers: pres_event_headers) do |csv|
        row = [job.id, exception.message, object.id, event['details'], event['end'], event['start'],
               event['type'], event['user'], event['outcome'], event['software_version']]

        csv << row
      end
    end
end
