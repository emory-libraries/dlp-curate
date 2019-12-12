# frozen_string_literal: true

# [Hydra-works-overwrite] CharacterizationService in Hydra::Works
# Adds 'append_original_checksum' method for adding three types of checksums
# to the hashValue predicate
Hydra::Works::CharacterizationService.class_eval do
  include PreservationEvents
  # Assign values of the instance properties from the metadata mapping :prop => val
  def store_metadata(terms)
    terms.each_pair do |term, value|
      property = property_for(term)
      next if property.nil? || property == :original_checksum
      # Array-ify the value to avoid a conditional here
      Array(value).each { |v| append_property_value(property, v) }
    end
    append_original_checksum(terms[:original_checksum]) if property_for(:original_checksum)
  end

  protected

    def append_original_checksum(value)
      event_start = DateTime.current
      value.first&.prepend("urn:md5:").to_s
      sha256_digest = Digest::SHA256.file(object.file_path[0]).hexdigest
      sha256 = sha256_digest.prepend("urn:sha256:")
      sha1 = object.digest.first.to_s
      value.push(sha1) if sha1
      value.push(sha256) if sha256
      object.send(:original_checksum=, value)
      # slice the file_set ID from object.id and pass to digest_preservation_event if object is saved
      digest_preservation_event(object.id.partition("/files").first, event_start, value) if object.id
    end

    def digest_preservation_event(file_set_id, event_start, value)
      file_set = FileSet.find(file_set_id)
      # create event for digest calculation/failure
      event = { 'type' => 'Message Digest Calculation', 'start' => event_start, 'details' => value,
                'software_version' => 'FITS v1.5.0, Fedora v4.7.5, Ruby Digest library', 'user' => file_set.depositor }
      event['outcome'] = value.size == 3 ? 'Success' : 'Failure'
      create_preservation_event(file_set, event)
    end
end
