# [Hydra-works-overwrite] CharacterizationService in Hydra::Works
# Adds 'append_original_checksum' method for adding three types of checksums
# to the hashValue predicate
Hydra::Works::CharacterizationService.class_eval do
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
      value.first.prepend("urn:md5:").to_s
      sha256_digest = Digest::SHA256.file(object.file_path[0]).hexdigest
      sha256 = sha256_digest.prepend("urn:sha256:")
      sha1 = object.digest.first.to_s
      value.push(sha1, sha256)
      object.send(:original_checksum=, value)
    end
end
