# frozen_string_literal: true

require "rails_helper"

RSpec.describe PreservationWorkflow do
  context "a new workflow" do
    let(:workflow_type)  { "default" }
    let(:workflow_notes) { "note example" }
    let(:workflow_rights_basis) { "example" }
    let(:workflow_rights_basis_note) { "default notes" }
    let(:workflow_rights_basis_date) { "2010-02-02" }
    let(:workflow_rights_basis_reviewer) { "Emory University" }
    let(:workflow_rights_basis_uri) { "http://loc.gov#example" }
    let(:work) { FactoryBot.build(:work, id: 'wk1', title: ['Work']) }
    let(:preservation_workflow) { work.preservation_workflow.build }

    it "can set a note" do
      preservation_workflow.workflow_notes = [workflow_notes]
      expect(preservation_workflow.workflow_notes).to eq [workflow_notes]
    end

    it "can set a workflow type" do
      preservation_workflow.workflow_type = [workflow_type]
      expect(preservation_workflow.workflow_type).to eq [workflow_type]
    end

    it "can set a workflow rights basis" do
      preservation_workflow.workflow_rights_basis = [workflow_rights_basis]
      expect(preservation_workflow.workflow_rights_basis).to eq [workflow_rights_basis]
    end

    it "can set a workflow rights basis note" do
      preservation_workflow.workflow_rights_basis_note = [workflow_rights_basis_note]
      expect(preservation_workflow.workflow_rights_basis_note).to eq [workflow_rights_basis_note]
    end

    it "can set a workflow rights basis date" do
      preservation_workflow.workflow_rights_basis_date = [workflow_rights_basis_date]
      expect(preservation_workflow.workflow_rights_basis_date).to eq [workflow_rights_basis_date]
    end

    it "can set a workflow rights basis reviewer" do
      preservation_workflow.workflow_rights_basis_reviewer = [workflow_rights_basis_reviewer]
      expect(preservation_workflow.workflow_rights_basis_reviewer).to eq [workflow_rights_basis_reviewer]
    end

    it "can set a workflow rights basis URI" do
      preservation_workflow.workflow_rights_basis_uri = [workflow_rights_basis_uri]
      expect(preservation_workflow.workflow_rights_basis_uri).to eq [workflow_rights_basis_uri]
    end
  end
end
