# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work CurateGenericWork`
module Hyrax
  class CurateGenericWorkPresenter < Hyrax::WorkShowPresenter
    CurateGenericWorkAttributes.instance.attributes.each do |key|
      delegate key.to_sym, to: :solr_document
    end

    # Change below was necessary to institute Source/Deposit Collection structure.
    # For more information, read the SOURCE_DEPOSIT_CHANGES_README.md in dlp-curate's root folder.
    delegate :failed_preservation_events, :source_collection_title, to: :solr_document

    include CuratePurl

    # [Hyrax-overwrite-v3.0.0.pre.rc1] We might not always have a request and a `base_url`,
    # therfore, we are using our CurateManifestHelper and passing in a hardcoded
    # host for creation of manifest_url

    def manifest_helper
      @manifest_helper ||= if request.nil?
                             CurateManifestHelper.new
                           else
                             ManifestHelper.new(request.base_url)
                           end
    end

    def manifest_url
      if request.nil?
        manifest_helper.polymorphic_url([:iiif_manifest], identifier: id, host: "http://#{ENV['HOSTNAME'] || 'localhost:3000'}")
      else
        manifest_helper.polymorphic_url([:iiif_manifest], identifier: id)
      end
    end

    def manifest_metadata
      [
        { "label" => "Provided by", "value" => holding_repository },
        { "label" => "Rights Status", "value" => "<a href=\"#{rights_statement_authority[:id]}\">#{rights_statement_authority[:term]}</a>" },
        { "label" => "Identifier", "value" => id },
        { "label" => "Persistent URL", "value" => "<a href=\"#{purl}\">#{purl}</a>" }
      ]
    end

    def visibility
      solr_document.human_readable_visibility
    end

    def preservation_workflows
      workflow_types = PreservationWorkflowImporter.workflow_types
      final = []
      ret_arr = []

      preservation_workflow_terms&.each do |pwf|
        final << JSON.parse(pwf)
      end

      workflow_types.each { |type| workflow_formatter(type, final, ret_arr) }
      ret_arr
    end

    # Below is an override of an attributes display method found in
    # Hyrax::PresentsAttributes, which is included by this Presenter via inheritance.
    def permission_badge
      permission_badge_class.new(solr_document['visibility_ssi']).render
    end

    private

      def workflow_formatter(type, flow_arr, ret_arr)
        workflow = flow_arr.find { |pwf| pwf["workflow_type"] == type } # get worfklow
        ret_arr << workflow_hash(workflow.compact) if workflow # make non nil value keys displayable
        ret_arr << { "Type" => type } unless workflow
      end

      def workflow_hash(wf)
        wf_copy = wf.clone
        wf.each_key do |key|
          wf_copy[key.split('_').map(&:capitalize).join(' ').remove('Workflow ')] = wf_copy.delete(key) # alter keys as per display requirements
        end
        wf_copy
      end

      def rights_statement_authority
        Qa::Authorities::Local.subauthority_for('rights_statements').find(rights_statement.first)
      end
  end
end
