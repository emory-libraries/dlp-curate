# frozen_string_literal: true

class CreatePreservationEventJob < Hyrax::ApplicationJob
  include PreservationEvents

  retry_on(Exception) do |job, exception|
    job.report_completely_failed_creation(job:, exception:) if exception&.message&.present?
  end

  def perform(object:, event:)
    create_preservation_event(object, event)
  end

  def report_completely_failed_creation(job:, exception:)
    CSV.open(file_path, "a+", write_headers: !csv_exists?, headers: pres_event_headers) do |csv|
      row = [job.job_id, exception.message, job.arguments, job&.arguments&.first&.[](:event)&.[]('details'),
             job&.arguments&.first&.[](:event)&.[]('end'), job&.arguments&.first&.[](:event)&.[]('start'),
             job&.arguments&.first&.[](:event)&.[]('type'), job&.arguments&.first&.[](:event)&.[]('user'),
             job&.arguments&.first&.[](:event)&.[]('outcome'), job&.arguments&.first&.[](:event)&.[]('software_version')]

      csv << row
    end
  end

  private

    def file_path
      "config/emory/failed_preservation_event_creations.csv"
    end

    def csv_exists?
      File.exist?(file_path)
    end

    def pres_event_headers
      ['Job ID', 'Exception', 'Arguments', 'event_details', 'event_end', 'event_start',
       'event_type', 'initiating_user', 'outcome', 'software_version']
    end
end
