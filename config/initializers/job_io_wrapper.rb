# frozen_string_literal: true
# [Hyrax-model-overwrite]
# ingest_file method in the JobIoWrapper method is modified. We save the response
# from the `file_actor.ingest_file` method call. If false is returned from L#16 in
# `config/intializers/file_actor.rb` then a failure event is created, else success
# event.

JobIoWrapper.class_eval do
  include PreservationEvents

  def self.create_with_varied_file_handling!(user:, file:, relation:, file_set:, preferred:)
    args = { user: user, relation: relation.to_s, file_set_id: file_set.id, preferred: preferred.to_s }
    if file.is_a?(Hyrax::UploadedFile)
      args[:uploaded_file] = file
      args[:path] = file.uploader.path
    elsif file.respond_to?(:path)
      args[:path] = file.path
      args[:original_name] = file.original_filename if file.respond_to?(:original_filename)
      args[:original_name] ||= file.original_name if file.respond_to?(:original_name)
    else
      raise "Require Hyrax::UploadedFile or File-like object, received #{file.class} object: #{file}"
    end
    create!(args)
  end

  def ingest_file
    event_start = DateTime.current
    file_name = file.path.to_s.split("/").last
    result = file_actor.ingest_file(self)
    if result == false
      outcome = 'Failure'
      details = "File not replicated to cross-region S3 storage: #{file_name}"
    else
      outcome = 'Success'
      details = "File replicated to cross-region S3 storage: #{file_name}"
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
