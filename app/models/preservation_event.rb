# frozen_string_literal: true
require 'active_triples'

class PreservationEvent < ActiveTriples::Resource
  include ActiveTriples::RDFSource
  include PreservationUri

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

  def preservation_event_terms
    attributes_map = { 'event_details' => event_details.first,
                       'event_end' => event_end.first,
                       'event_start' => event_start.first,
                       'event_type' => event_type.first,
                       'initiating_user' => initiating_user.first,
                       'outcome' => outcome.first,
                       'software_version' => software_version.first }
    attributes_map.to_json
  end

  def failed_event_json
    { "event_details" => event_details.first, "event_start" => event_start.first }.to_json
  end
end
