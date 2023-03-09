# frozen_string_literal: true

class ProcessAwsFixityPreservationEventsJob < Hyrax::ApplicationJob
  include PreservationEvents

  def perform(csv)
    lines = CSV.read(csv, headers: true)

    Rails.logger.info "AWS Fixity Event processing of #{csv} started at #{DateTime.current}"
    lines.each { |l| process_line(l) }
    Rails.logger.info "AWS Fixity Event processing of #{csv} ended at #{DateTime.current}"
  end

  private

    def process_line(line)
      event_obj = AwsFixityEvent.new(line)
      return if event_obj.sha1.blank?
      file_set = FileSet.where(sha1_tesim: event_obj.sha1)&.first
      return if file_set.blank?
      event = event_obj.process_event
      return if check_for_preexisting_preservation_events(file_set, event_obj.sha1, event_obj.fixity_start)

      create_preservation_event(file_set, event)
    end
end
