# frozen_string_literal: true

class PreservationWorkflowImporter
  @workflow_types = ['Ingest', 'Accession', 'Deletion', 'Decommission']
  class << self
    attr_reader :workflow_types

    def import(csv_file, log_location = STDOUT)
      @logger = Logger.new(log_location)
      CSV.foreach(csv_file, headers: true) do |row|
        workflow_attrs = row.to_hash
        next unless workflow_attrs['type'] == 'work' && workflow_attrs.values.compact.count > 2 # ignore file_sets and check if workflows actually have values
        work = find_work(workflow_attrs['deduplication_key'])
        unless work
          @logger.error "No work found with deduplication_key #{workflow_attrs['deduplication_key']}"
          next
        end

        work.is_a?(Valkyrie::Resource) ? update_valkyrie_work(work, workflow_attrs) : update_af_work(work, workflow_attrs)
        @logger.info "Updated preservation_workflow for #{work.title.first}"
      end
    end

    private

      # Valkyrie works are not found through ActiveFedora, so look the work up in Solr.
      # Works not yet migrated keep being updated through ActiveFedora, which does not migrate them.
      def find_work(deduplication_key)
        return CurateGenericWork.where(deduplication_key:).first unless Hyrax.config.valkyrie_transition?

        doc = Hyrax::SolrService.query("{!field f=deduplication_key_tesim}#{deduplication_key}",
                                       fq: 'has_model_ssim:CurateGenericWork', fl: 'id,deduplication_key_tesim', rows: 10)
                                .find { |d| Array(d['deduplication_key_tesim']).include?(deduplication_key) }
        return unless doc

        work = Hyrax.query_service.find_by(id: doc['id'])
        work.wings? ? CurateGenericWork.find(doc['id']) : work
      end

      def update_af_work(work, workflow_attrs)
        check_workflows_exists?(work)
        @workflow_types.each { |type| update_workflow(type, work, workflow_attrs) }
        work.save!
      end

      def update_valkyrie_work(work, workflow_attrs)
        kept = work.preservation_workflow.reject { |w| @workflow_types.include?(w.workflow_type) } # existing workflows are replaced
        work.preservation_workflow = kept + @workflow_types.map { |type| PreservationWorkflowResource.new(workflow_params(type, workflow_attrs)) }
        saved = Hyrax.persister.save(resource: work)
        Hyrax.index_adapter.save(resource: saved)
      end

      def check_workflows_exists?(work)
        @workflow_types.each do |type|
          found_work = work.preservation_workflow.find { |w| w.workflow_type == [type] }
          work.preservation_workflow.delete(found_work) if found_work # we first delete existing workflow and then update
        end
      end

      def update_workflow(type, work, workflow_attrs)
        work.preservation_workflow_attributes = [workflow_params(type, workflow_attrs)]
      end

      def workflow_params(type, workflow_attrs)
        { workflow_type:                  type,
          workflow_notes:                 workflow_attrs["#{type}.workflow_notes"].presence || workflow_attrs["#{type}.workflow_note"],
          workflow_rights_basis:          workflow_attrs["#{type}.workflow_rights_basis"],
          workflow_rights_basis_note:     workflow_attrs["#{type}.workflow_rights_basis_note"],
          workflow_rights_basis_date:     workflow_attrs["#{type}.workflow_rights_basis_date"],
          workflow_rights_basis_reviewer: workflow_attrs["#{type}.rights_basis_reviewer"].presence || workflow_attrs["#{type}.workflow_rights_basis_reviewer"],
          workflow_rights_basis_uri:      workflow_attrs["#{type}.workflow_rights_basis_uri"] }
      end
  end
end
