# frozen_string_literal: true

class ProcessAwsFixityPreservationEventsJob < Hyrax::ApplicationJob
  include PreservationEvents

  def perform(csv)
    lines = CSV.read(csv, headers: true)

    Rails.logger.info "AWS Fixity Event processing of #{csv} started at #{DateTime.current}"
    process_lines(lines)
    Rails.logger.info "AWS Fixity Event processing of #{csv} ended at #{DateTime.current}"
  end

  private

    def process_lines(lines)
      lines.each do |l|
        event_obj = AwsFixityEvent.new(l)
        next if event_obj.sha1.blank?
        file_set = FileSet.where(sha1_tesim: event_obj.sha1)&.first
        next if file_set.blank?
        event = event_obj.process_event

        create_preservation_event(file_set, event)
      end
    end
end
