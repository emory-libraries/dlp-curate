# frozen_string_literal: true

class PreservationWorkflowImporter
  @workflow_types = ['Ingest', 'Accession', 'Deletion', 'Decommission']
  class << self
    attr_reader :workflow_types

    def import(csv_file, log_location = STDOUT)
      CSV.foreach(csv_file, headers: true) do |row|
        workflow_attrs = row.to_hash
        next unless workflow_attrs['type'] == 'work' && workflow_attrs.values.compact.count > 2 # ignore file_sets and check if workflows actually have values
        work = CurateGenericWork.where(deduplication_key: workflow_attrs['deduplication_key']).first
        check_workflows_exists?(work)
        @workflow_types.each { |type| update_workflow(type, work, workflow_attrs) }
        work.save!
        @logger = Logger.new(log_location)
        @logger.info "Updated preservation_workflow for #{work.title.first}"
      end
    end

    private

      def check_workflows_exists?(work)
        @workflow_types.each do |type|
          found_work = work.preservation_workflow.find { |w| w.workflow_type == [type] }
          work.preservation_workflow.delete(found_work) if found_work # we first delete existing workflow and then update
        end
      end

      def update_workflow(type, work, workflow_attrs)
        work.preservation_workflow_attributes = [
          { workflow_type:                  type,
            workflow_notes:                 workflow_attrs["#{type}.workflow_notes"].presence || workflow_attrs["#{type}.workflow_note"],
            workflow_rights_basis:          workflow_attrs["#{type}.workflow_rights_basis"],
            workflow_rights_basis_note:     workflow_attrs["#{type}.workflow_rights_basis_note"],
            workflow_rights_basis_date:     workflow_attrs["#{type}.workflow_rights_basis_date"],
            workflow_rights_basis_reviewer: workflow_attrs["#{type}.rights_basis_reviewer"].presence || workflow_attrs["#{type}.workflow_rights_basis_reviewer"] }
        ]
      end
  end
end
