# frozen_string_literal: true

# Opens FitsDocument class from Hydra::Works::Characterization
# and adds fits mapping for extra technical metadata
Hydra::Works::Characterization::FitsDocument.class_eval do
  PROXIED_TERMS = Object.const_get 'Hydra::Works::Characterization::FitsDocument::PROXIED_TERMS'
  NEW_PROXIED_TERMS = PROXIED_TERMS.dup + %i[file_path creating_os creating_application_name puid].freeze

  def self.terminology
    struct = Struct.new(:proxied_term).new
    terminology = Struct.new(:terms)
    terminology.new(NEW_PROXIED_TERMS.map { |t| [t, struct] }.to_h)
  end

  def file_path
    ng_xml.css("fits > fileinfo > filepath").map(&:text)
  end

  def creating_os
    ng_xml.css("fits > fileinfo > creatingos").map(&:text)
  end

  def creating_application_name
    ng_xml.css("fits > fileinfo > creatingApplicationName").map(&:text)
  end

  def puid
    ng_xml.css("fits > identification > identity > externalIdentifier[type='puid']").map(&:text)
  end
end
