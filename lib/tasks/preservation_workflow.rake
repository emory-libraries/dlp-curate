# frozen_string_literal: true
namespace :curate do
  namespace :works do
    desc "Bulk-import preservation workflow metadata for works"
    task import_preservation_workflows: :environment do
      preservation_workflow_csv = Rails.root.join('config', 'preservation_workflow_metadata', 'preservation_workflows.csv')
      PreservationWorkflowImporter.import(preservation_workflow_csv)
    end
  end
end
