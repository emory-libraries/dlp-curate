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
      row = process_row(job:, exception:)

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
      ['Job ID', 'Exception', 'Object ID', 'event_details', 'event_end', 'event_start',
       'event_type', 'initiating_user', 'outcome', 'software_version']
    end

    def process_row(job:, exception:)
      [job.job_id, exception.message, pertinent_arguments(job:)&.[](:object)&.id, pertinent_event(job:)&.[]('details'),
       pertinent_event(job:)&.[]('end'), pertinent_event(job:)&.[]('start'), pertinent_event(job:)&.[]('type'),
       pertinent_event(job:)&.[]('user'), pertinent_event(job:)&.[]('outcome'), pertinent_event(job:)&.[]('software_version')]
    end

    def pertinent_arguments(job:)
      @pertinent_arguments ||= job&.arguments&.first
    end

    def pertinent_event(job:)
      @pertinent_event ||= pertinent_arguments(job:)&.[](:event)
    end
end
