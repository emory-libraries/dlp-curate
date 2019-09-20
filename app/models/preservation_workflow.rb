# frozen_string_literal: true
require 'active_triples'
require 'json'

class PreservationWorkflow < ActiveTriples::Resource
  include ActiveTriples::RDFSource

  property :workflow_type, predicate: "http://metadata.emory.edu/vocab/cor-terms#workflowType", multiple: false
  property :workflow_notes, predicate: "http://metadata.emory.edu/vocab/cor-terms#workflowNote", multiple: false
  property :workflow_rights_basis, predicate: "http://metadata.emory.edu/vocab/cor-terms#workflowRightsBasis", multiple: false
  property :workflow_rights_basis_note, predicate: "http://metadata.emory.edu/vocab/cor-terms#workflowRightsBasisNote", multiple: false
  property :workflow_rights_basis_date, predicate: "http://metadata.emory.edu/vocab/cor-terms#workflowRightsBasisDate", multiple: false
  property :workflow_rights_basis_reviewer, predicate: "http://metadata.emory.edu/vocab/cor-terms#workflowRightsBasisReviewer", multiple: false
  property :workflow_rights_basis_uri, predicate: "http://metadata.emory.edu/vocab/cor-terms#workflowRightsBasisURI", multiple: false

  # We need to convert the URI on initialize so that
  # ActiveTriples can create a 'hash URI' for this
  # resource.  This is necessary so that we can edit
  # nested committee members within the ETD edit form.
  # (Without the hash URI, we wouldn't be able to edit
  # the committee member in the same sparql query as the
  # ETD.)
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

  def preservation_terms
    attributes_map = { 'workflow_type' => workflow_type.first,
                       'workflow_notes' => workflow_notes.first,
                       'workflow_rights_basis' => workflow_rights_basis.first,
                       'workflow_rights_basis_note' => workflow_rights_basis_note.first,
                       'workflow_rights_basis_date' => workflow_rights_basis_date.first,
                       'workflow_rights_basis_reviewer' => workflow_rights_basis_reviewer.first,
                       'workflow_rights_basis_uri' => workflow_rights_basis_uri.first }
    attributes_map.to_json
  end
end
