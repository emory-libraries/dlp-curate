# frozen_string_literal: true

class PreservationWorkflowResource < Hyrax::Resource
  include Hyrax::Schema(:preservation_workflow_metadata)

  TERMS = %w[workflow_type workflow_notes workflow_rights_basis workflow_rights_basis_note
             workflow_rights_basis_date workflow_rights_basis_reviewer workflow_rights_basis_uri].freeze

  # Copies an AF PreservationWorkflow, whose properties are single-valued relations.
  # @param workflow [PreservationWorkflow]
  # @return [PreservationWorkflowResource]
  def self.from_active_fedora(workflow)
    new(TERMS.to_h { |term| [term.to_sym, workflow.public_send(term).first] })
  end

  # Same JSON as the AF PreservationWorkflow#preservation_terms, which the work page reads from Solr.
  def preservation_terms
    TERMS.index_with { |term| public_send(term) }.to_json
  end
end
