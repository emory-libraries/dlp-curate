# frozen_string_literal: true

class ManifestRegenerationController < ApplicationController
  before_action :authenticate_user!
  include IiifManifestCache

  def regen_manifest
    solr_doc = SolrDocument.find(params[:work_id])
    ManifestBuilderService.regenerate_manifest(presenter: presenter(solr_doc), curation_concern: CurateGenericWork.find(params[:work_id]))
    redirect_to hyrax_curate_generic_work_path(params[:work_id])
  end

  private

    # @param [SolrDocument] document
    def presenter(document)
      ability = ManifestAbility.new
      Hyrax::CurateGenericWorkPresenter.new(document, ability)
    end
end
