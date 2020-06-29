# frozen_string_literal: true
require 'rails_helper'

RSpec.describe PreservationWorkflowImporter, :clean do
  let(:generic_work) { CurateGenericWork.where(deduplication_key: 'MSS1218_B071_I205').first }
  let(:csv)          { fixture_path + '/preservation_workflows.csv' }
  let(:csv2)         { fixture_path + '/preservation_workflows2.csv' }

  describe "#import" do
    before do
      CurateGenericWork.create(title: ['Example title'], deduplication_key: 'MSS1218_B071_I205')
      described_class.import(csv)
    end

    context "with new preservation_workflow for the work" do
      it "creates new preservation_workflows" do
        expect(generic_work.preservation_workflow.count).to eq 4
        expect(generic_work.preservation_workflow.pluck(:workflow_type)).to match_array described_class.workflow_types.map { |v| [v] }
      end

      ['Ingest', 'Accession'].each do |type|
        include_examples 'check_basis_reviewer_for_text', type, 'Scholarly Communications Office'
      end

      ['Deletion', 'Decommission'].each do |type|
        include_examples 'check_basis_reviewer_for_text', type, 'Woodruff Health Sciences Library Administration'
      end
    end

    context "with existing preservation_workflow for the work" do
      before do
        described_class.import(csv2)
      end

      it "updates preservation_workflow" do
        expect(generic_work.preservation_workflow.count).to eq 4
      end

      include_examples 'check_basis_reviewer_for_text', 'Accession', 'LTDS'
    end
  end
end
