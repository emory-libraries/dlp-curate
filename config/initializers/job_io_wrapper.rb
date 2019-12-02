# frozen_string_literal: true
# [Hyrax-model-overwrite]
# ingest_file method in the JobIoWrapper method is modified. We save the response
# from the `file_actor.ingest_file` method call. If false is returned from L#16 in
# `config/intializers/file_actor.rb` then a failure event is created, else success
# event.

JobIoWrapper.class_eval do
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
end
