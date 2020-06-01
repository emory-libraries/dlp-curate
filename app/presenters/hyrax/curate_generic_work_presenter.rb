# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work CurateGenericWork`
module Hyrax
  class CurateGenericWorkPresenter < Hyrax::WorkShowPresenter
    CurateGenericWorkAttributes.instance.attributes.each do |key|
      delegate key.to_sym, to: :solr_document
    end
    delegate :failed_preservation_events, to: :solr_document

    include CuratePurl

    # [Hyrax-overwrite] We might not always have a request and a `base_url`,
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
        { "label" => "Rights Status", "value" => rights_statement },
        { "label" => "Identifier", "value" => id },
        { "label" => "Persistent URL", "value" => "<a href=\"#{purl}\">#{purl}</a>" }
      ]
    end

    def visibility
      solr_document.human_readable_visibility
    end

    def failed_preservation_events
      solr_document.failed_preservation_events
    end

    def preservation_workflows
      final = []
      preservation_workflow_terms&.each do |pwf|
        final << JSON.parse(pwf)
      end
      accession = final.select { |pwf| pwf["workflow_type"] == "Accession" }.first # get accession worfklow
      accession_result = workflow_hash(accession.compact) if accession # make non nil value keys displayable
      ingest = final.select { |pwf| pwf["workflow_type"] == "Ingest" }.first # get ingest workflow
      ingest_result = workflow_hash(ingest.compact) if ingest # make non nil value keys displayable
      [accession_result || { "Type" => "Accession" }, ingest_result || { "Type" => "Ingest" }] # send result or only type if a result is nil
    end

    private

      def workflow_hash(wf)
        wf_copy = wf.clone
        wf.each_key do |key|
          wf_copy[key.split('_').map(&:capitalize).join(' ').remove('Workflow ')] = wf_copy.delete(key) # alter keys as per display requirements
        end
        wf_copy
      end
  end
end
