# frozen_string_literal: true

class PreservationWorkflowImporter
  class << self
    def import(csv_file, log_location = STDOUT)
      CSV.foreach(csv_file, headers: true) do |row|
        workflow_attrs = row.to_hash
        next unless workflow_attrs['type'] == 'work' && workflow_attrs.values.compact.count > 2 # ignore file_sets and check if workflows actually have values
        work = CurateGenericWork.where(deduplication_key: workflow_attrs['deduplication_key']).first
        check_workflow_exists?(work)
        update_ingest_workflow(work, workflow_attrs)
        update_accession_workflow(work, workflow_attrs)
        work.save!
        @logger = Logger.new(log_location)
        @logger.info "Updated preservation_workflow for #{work.title.first}"
      end
    end

    private

      def check_workflow_exists?(work)
        ingest = work.preservation_workflow.select { |w| w.workflow_type == ["Ingest"] }.first
        work.preservation_workflow.delete(ingest) if ingest # we first delete existing workflow and then update
        accession = work.preservation_workflow.select { |w| w.workflow_type == ["Accession"] }.first
        work.preservation_workflow.delete(accession) if accession # we first delete existing workflow and then update
      end

      def update_ingest_workflow(work, workflow_attrs)
        work.preservation_workflow_attributes = [{ workflow_type: 'Ingest',
                                                   workflow_notes: workflow_attrs['Ingest.workflow_notes'],
                                                   workflow_rights_basis: workflow_attrs['Ingest.workflow_rights_basis'],
                                                   workflow_rights_basis_note: workflow_attrs['Ingest.workflow_rights_basis_note'],
                                                   workflow_rights_basis_date: workflow_attrs['Ingest.workflow_rights_basis_date'],
                                                   workflow_rights_basis_reviewer: workflow_attrs['Ingest.rights_basis_reviewer'] }]
      end

      def update_accession_workflow(work, workflow_attrs)
        work.preservation_workflow_attributes = [{ workflow_type: 'Accession',
                                                   workflow_rights_basis: workflow_attrs['Accession.workflow_rights_basis'],
                                                   workflow_rights_basis_note: workflow_attrs['Accession.workflow_rights_basis_note'],
                                                   workflow_rights_basis_date: workflow_attrs['Accession.workflow_rights_basis_date'],
                                                   workflow_rights_basis_reviewer: workflow_attrs['Accession.workflow_rights_basis_reviewer'] }]
      end
  end
end
