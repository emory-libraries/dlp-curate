# frozen_string_literal: true
require 'rails_helper'

RSpec.describe PreservationWorkflowImporterJob, :clean do
  let(:generic_work) { CurateGenericWork.where(deduplication_key: 'MSS1218_B071_I205').first }
  let(:csv)          { fixture_path + '/preservation_workflows.csv' }

  before do
    CurateGenericWork.create(title: ['Example title'], deduplication_key: 'MSS1218_B071_I205')
  end

  it 'processes preservation workflow preservation metadata' do
    described_class.perform_now(csv)
    expect(generic_work.preservation_workflow.count).to eq 4
  end
end
