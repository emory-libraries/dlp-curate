# frozen_string_literal: true

class ManifestRegenerationController < ApplicationController
  before_action :authenticate_user!
  include IiifManifestCache

  def regen_manifest
    solr_doc = SolrDocument.find(params[:work_id])
    key = solr_doc[:manifest_cache_key_tesim]&.first.to_s + '_' + params[:work_id]
    file_path = File.join(iiif_manifest_cache, key)
    File.delete(file_path) if File.exist?(file_path)
    ManifestBuilderService.build_manifest(presenter: presenter(solr_doc), curation_concern: CurateGenericWork.find(params[:work_id]))
    redirect_to hyrax_curate_generic_work_path(params[:work_id])
  end

  private

    # @param [SolrDocument] document
    def presenter(document)
      ability = ManifestAbility.new
      Hyrax::CurateGenericWorkPresenter.new(document, ability)
    end
end
