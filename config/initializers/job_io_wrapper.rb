# frozen_string_literal: true
# [Hyrax-model-overwrite]
# ingest_file method in the JobIoWrapper method is modified. We save the response
# from the `file_actor.ingest_file` method call. If false is returned from L#16 in
# `config/intializers/file_actor.rb` then a failure event is created, else success
# event.

JobIoWrapper.class_eval do
  include PreservationEvents

  def ingest_file
    event_start = DateTime.current
    file_name = file.path.to_s.split("/").last
    result = file_actor.ingest_file(self)
    if result == false
      outcome = 'Failure'
      details = "#{file_name} could not be submitted for preservation storage"
    else
      outcome = 'Success'
      details = "#{file_name} submitted for preservation storage"
    end
    file_set_preservation_event(file_set, event_start, outcome, details)
  end

  private

    # create preservation_event for fileset creation (method in PreservationEvents module)
    def file_set_preservation_event(file_set, event_start, outcome, details)
      event = { 'type' => 'File submission', 'start' => event_start, 'outcome' => outcome, 'details' => details,
                'software_version' => 'Fedora v4.7.5', 'user' => user.uid }
      create_preservation_event(file_set, event)
    end
end
