# frozen_string_literal: true

class ProcessAwsFixityPreservationEventsJob < Hyrax::ApplicationJob
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
      file_set = find_file_set_by_sha1(event_obj.sha1)
      return if file_set.blank?
      event = event_obj.process_event
      return if check_for_preexisting_preservation_events(file_set, event_obj.sha1, event_obj.fixity_start)

      CreatePreservationEventJob.perform_later(object: file_set, event:)
    end

    def find_file_set_by_sha1(sha1)
      if Hyrax.config.valkyrie_transition?
        results = Hyrax::SolrService.query("sha1_tesim:#{sha1}", rows: 1, fl: "id")
        return nil if results.blank?
        Hyrax.query_service.find_by(id: results.first["id"])
      else
        FileSet.where(sha1_tesim: sha1)&.first
      end
    end
end
