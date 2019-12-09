# frozen_string_literal: true
# [Hyrax-overwrite]
# Adds file_set_preservation_event which creates a fixity_check
# preservation_event

Hyrax::FileSetFixityCheckService.class_eval do
  include PreservationEvents

  def fixity_check
    event_start = DateTime.current
    results = file_set.files.collect { |f| fixity_check_file(f) }

    file_set_preservation_event(results, event_start)

    return if async_jobs

    results.flatten.group_by(&:file_id)
  end

  private

    def file_set_preservation_event(results, event_start)
      fixity_file_set = file_set
      failures = results.select { |v| v.first['passed'] == false }
      event = { 'type' => 'Fixity Check', 'start' => event_start,
                'software_version' => 'Fedora v4.7.5', 'user' => fixity_file_set.depositor }
      failure_files = []
      if failures.empty?
        event['outcome'] = 'Success'
        event['details'] = 'Fixity intact for all files'
        create_preservation_event(fixity_file_set, event)
      else
        failures.each { |f| failure_files << Hydra::PCDM::File&.find(f.first.file_id) }
      end
      failure_files.each do |f|
        event['outcome'] = 'Failure'
        event['details'] = "Fixity check failed for: #{f&.original_name}: sha1:#{f&.checksum&.value}"
        create_preservation_event(fixity_file_set, event)
      end
    end
end
