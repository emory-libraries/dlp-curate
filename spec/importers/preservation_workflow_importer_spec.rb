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

      it 'populates the workflow_rights_basis_uri' do
        rights_basis_uri_array = generic_work.preservation_workflow.map { |workflow| workflow.workflow_rights_basis_uri.first }.uniq
        expect(rights_basis_uri_array).to eq ['https://someawesomewebsite.com']
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

  describe "#import during the Valkyrie transition" do
    let(:csv) { fixture_path + '/preservation_workflows.csv' }
    let(:csv2) { fixture_path + '/preservation_workflows2.csv' }
    let(:work_id) { Valkyrie::ID.new('work-1') }
    let(:work) { CurateGenericWorkResource.new(id: work_id, title: ['Valkyrie work'], deduplication_key: 'MSS1218_B071_I205') }
    let(:saved) { [] }
    let(:solr_docs) { [{ 'id' => work_id.to_s, 'deduplication_key_tesim' => ['MSS1218_B071_I205'] }] }

    before do
      allow(Hyrax.config).to receive(:valkyrie_transition?).and_return(true)
      allow(Hyrax::SolrService).to receive(:query).and_return(solr_docs)
      allow(Hyrax.query_service).to receive(:find_by).with(id: work_id.to_s) { saved.last || work }
      allow(Hyrax.persister).to receive(:save) { |resource:| saved << resource && resource }
      allow(Hyrax.index_adapter).to receive(:save)
    end

    def reviewer_for(type)
      saved.last.preservation_workflow.find { |w| w.workflow_type == type }.workflow_rights_basis_reviewer
    end

    it "saves the workflows on the Valkyrie work and reindexes it" do
      described_class.import(csv, File::NULL)

      expect(saved.last.preservation_workflow.map(&:workflow_type)).to match_array described_class.workflow_types
      expect(reviewer_for('Ingest')).to eq 'Scholarly Communications Office'
      expect(Hyrax.index_adapter).to have_received(:save).with(resource: saved.last)
    end

    it "replaces the existing workflows when imported again" do
      described_class.import(csv, File::NULL)
      described_class.import(csv2, File::NULL)

      expect(saved.last.preservation_workflow.count).to eq 4
      expect(reviewer_for('Accession')).to eq 'LTDS'
    end

    context "when no work has the deduplication_key" do
      let(:solr_docs) { [] }

      it "logs it and skips the row" do
        log = StringIO.new

        expect { described_class.import(csv, log) }.not_to raise_error
        expect(log.string).to include 'No work found with deduplication_key MSS1218_B071_I205'
        expect(Hyrax.persister).not_to have_received(:save)
      end
    end
  end
end
