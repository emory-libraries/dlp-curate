# frozen_string_literal: true
require "rails_helper"

RSpec.describe PreservationWorkflowResource do
  let(:attributes) do
    { workflow_type: 'Ingest', workflow_notes: 'Migrated from Extensis Portfolio', workflow_rights_basis: 'Administrative Signoff',
      workflow_rights_basis_note: 'A note', workflow_rights_basis_date: '3/1/16',
      workflow_rights_basis_reviewer: 'Scholarly Communications Office', workflow_rights_basis_uri: 'https://example.com' }
  end
  let(:af_workflow) do
    work = CurateGenericWork.new
    work.preservation_workflow_attributes = [attributes]
    work.preservation_workflow.first
  end

  describe '#preservation_terms' do
    it 'matches the JSON the AF PreservationWorkflow indexes for the work page' do
      expect(described_class.new(attributes).preservation_terms).to eq af_workflow.preservation_terms
    end
  end

  describe '.from_active_fedora' do
    it 'copies every term of the AF workflow' do
      expect(described_class.from_active_fedora(af_workflow).attributes.slice(*attributes.keys)).to eq attributes
    end
  end

  describe 'as a CurateGenericWorkResource attribute' do
    it 'builds workflows from hashes' do
      work = CurateGenericWorkResource.new(preservation_workflow: [attributes])

      expect(work.preservation_workflow.map(&:workflow_type)).to eq ['Ingest']
    end

    it 'drops the URI references Wings passes for nested AF objects' do
      work = CurateGenericWorkResource.new(preservation_workflow: [RDF::URI('http://example.com/work#nested_1'), described_class.new(attributes)])

      expect(work.preservation_workflow.map(&:workflow_type)).to eq ['Ingest']
    end
  end
end
