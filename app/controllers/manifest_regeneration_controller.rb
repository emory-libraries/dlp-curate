# frozen_string_literal: true

class ManifestRegenerationController < ApplicationController
  before_action :authenticate_user!
  include IiifManifestCache

  def regen_manifest
    solr_doc = SolrDocument.find(params[:work_id])
    ManifestBuilderService.regenerate_manifest(presenter: presenter(solr_doc), curation_concern: load_curation_concern_for_manifest(params[:work_id]))
    redirect_to hyrax_curate_generic_work_path(params[:work_id])
  end

  private

    # @param [SolrDocument] document
    def presenter(document)
      ability = ManifestAbility.new
      Hyrax::CurateGenericWorkPresenter.new(document, ability)
    end

    # Loads the curation concern for IIIF manifest regeneration. Supports both
    # AF and Valkyrie works during lazy migration.
    # @note NOTE: ManifestBuilderService itself is still AF-centric and must be
    #   updated for full Valkyrie parity.
    def load_curation_concern_for_manifest(id)
      if Hyrax.config.valkyrie_transition?
        Hyrax.query_service.find_by(id:)
      else
        CurateGenericWork.find(id)
      end
    end
end
