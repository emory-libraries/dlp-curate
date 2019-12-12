# frozen_string_literal: true

module PreservationUri
  # This is required else the URI generated for the
  # nested attribute will have a different parent
  # instead of `/rest/prod/#{work_id}` in fedora.
  # This code was taken from an example spec in the
  # active-fedora gem:
  # spec/integration/nested_hash_resources_spec.rb
  def initialize(uri, parent)
    if uri.try(:node?)
      uri = RDF::URI("#nested_#{uri.to_s.gsub('_:', '')}")
    elsif uri.start_with?("#")
      uri = RDF::URI(uri)
    end
    super
  end
end
