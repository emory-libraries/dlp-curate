# frozen_string_literal: true
require 'active_triples'

class PreservationEvent < ActiveTriples::Resource
  include ActiveTriples::RDFSource

  property :event_details, predicate: "http://metadata.emory.edu/vocab/cor-terms#eventDetails", multiple: false
  property :event_end, predicate: "http://metadata.emory.edu/vocab/cor-terms#eventEnd", multiple: false
  property :event_id, predicate: "http://metadata.emory.edu/vocab/cor-terms#eventIdentifier", multiple: false
  property :event_start, predicate: "http://metadata.emory.edu/vocab/cor-terms#eventStart", multiple: false
  property :event_type, predicate: "http://metadata.emory.edu/vocab/cor-terms#eventType", multiple: false
  property :fileset_id, predicate: "http://metadata.emory.edu/vocab/cor-terms#filesetRelatedObject", multiple: false
  property :initiating_user, predicate: "http://metadata.emory.edu/vocab/cor-terms#eventUser", multiple: false
  property :outcome, predicate: "http://metadata.emory.edu/vocab/cor-terms#eventOutcome", multiple: false
  property :software_version, predicate: "http://metadata.emory.edu/vocab/cor-terms#softwareVersion", multiple: false
  property :workflow_id, predicate: "http://metadata.emory.edu/vocab/cor-terms#workflowRelatedObject", multiple: false

  def initialize(uri, parent)
    if uri.try(:node?)
      uri = RDF::URI("#events_#{uri.to_s.gsub('_:', '')}")
    elsif uri.start_with?("#")
      uri = RDF::URI(uri)
    end
    super
  end
end
