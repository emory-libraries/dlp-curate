# frozen_string_literal: true

require 'rails_helper'

# Tests the valkyrie_transition? dual-path logic across controllers.
# These specs verify that controllers correctly branch between AF and Valkyrie
# resource loading based on Hyrax.config.valkyrie_transition?.
RSpec.describe 'Valkyrie dual-path controller logic', type: :controller do
  let(:user) { FactoryBot.create(:user) }
  let(:file_set_id) { 'fs-abc-123' }
  let(:work_id) { 'work-xyz-456' }

  describe CharacterizationController do
    controller(CharacterizationController) {}

    before { sign_in user }

    describe '#load_file_set (private)' do
      context 'when valkyrie_transition? is true' do
        let(:valkyrie_file_set) { instance_double('FileSetResource', id: file_set_id) }

        before do
          allow(Hyrax.config).to receive(:valkyrie_transition?).and_return(true)
          allow(Hyrax.query_service).to receive(:find_by).with(id: file_set_id).and_return(valkyrie_file_set)
          allow(ReCharacterizeJob).to receive(:perform_later)
        end

        it 'loads the file set via Hyrax.query_service' do
          post :re_characterize, params: { file_set_id: }, xhr: true
          expect(Hyrax.query_service).to have_received(:find_by).with(id: file_set_id)
        end

        it 'passes the Valkyrie file set to ReCharacterizeJob' do
          post :re_characterize, params: { file_set_id: }, xhr: true
          expect(ReCharacterizeJob).to have_received(:perform_later).with(file_set: valkyrie_file_set, user: user.uid)
        end
      end

      context 'when valkyrie_transition? is false' do
        let(:af_file_set) { instance_double('FileSet', id: file_set_id) }

        before do
          allow(Hyrax.config).to receive(:valkyrie_transition?).and_return(false)
          allow(FileSet).to receive(:find).with(file_set_id).and_return(af_file_set)
          allow(ReCharacterizeJob).to receive(:perform_later)
        end

        it 'loads the file set via FileSet.find' do
          post :re_characterize, params: { file_set_id: }, xhr: true
          expect(FileSet).to have_received(:find).with(file_set_id)
        end

        it 'passes the AF file set to ReCharacterizeJob' do
          post :re_characterize, params: { file_set_id: }, xhr: true
          expect(ReCharacterizeJob).to have_received(:perform_later).with(file_set: af_file_set, user: user.uid)
        end
      end
    end
  end

  describe ManifestRegenerationController do
    controller(ManifestRegenerationController) {}

    before { sign_in user }

    describe '#load_curation_concern_for_manifest (private)' do
      let(:solr_document) do
        SolrDocument.new(
          'id' => work_id,
          'title_tesim' => ['Test Work'],
          'human_readable_type_tesim' => ['Curate Generic Work'],
          'has_model_ssim' => ['CurateGenericWork'],
          'manifest_cache_key_tesim' => 'abc123'
        )
      end
      let(:presenter) { instance_double(Hyrax::CurateGenericWorkPresenter) }

      before do
        allow(SolrDocument).to receive(:find).and_return(solr_document)
        allow(Hyrax::CurateGenericWorkPresenter).to receive(:new).and_return(presenter)
        allow(ManifestBuilderService).to receive(:regenerate_manifest)
      end

      context 'when valkyrie_transition? is true' do
        let(:valkyrie_work) { instance_double('CurateGenericWorkResource', id: work_id) }

        before do
          allow(Hyrax.config).to receive(:valkyrie_transition?).and_return(true)
          allow(Hyrax.query_service).to receive(:find_by).with(id: work_id).and_return(valkyrie_work)
        end

        it 'loads the work via Hyrax.query_service' do
          post :regen_manifest, params: { work_id: }, xhr: true
          expect(Hyrax.query_service).to have_received(:find_by).with(id: work_id)
        end

        it 'passes the Valkyrie resource to ManifestBuilderService' do
          post :regen_manifest, params: { work_id: }, xhr: true
          expect(ManifestBuilderService).to have_received(:regenerate_manifest)
            .with(presenter:, curation_concern: valkyrie_work)
        end
      end

      context 'when valkyrie_transition? is false' do
        let(:af_work) { instance_double('CurateGenericWork', id: work_id) }

        before do
          allow(Hyrax.config).to receive(:valkyrie_transition?).and_return(false)
          allow(CurateGenericWork).to receive(:find).with(work_id).and_return(af_work)
        end

        it 'loads the work via CurateGenericWork.find' do
          post :regen_manifest, params: { work_id: }, xhr: true
          expect(CurateGenericWork).to have_received(:find).with(work_id)
        end

        it 'passes the AF object to ManifestBuilderService' do
          post :regen_manifest, params: { work_id: }, xhr: true
          expect(ManifestBuilderService).to have_received(:regenerate_manifest)
            .with(presenter:, curation_concern: af_work)
        end
      end
    end
  end

  describe 'IiifController#load_curation_concern_for_manifest' do
    let(:controller_instance) { IiifController.new }

    before do
      allow(controller_instance).to receive(:params).and_return({})
    end

    context 'when valkyrie_transition? is true' do
      let(:valkyrie_work) { instance_double('CurateGenericWorkResource', id: work_id) }

      before do
        allow(Hyrax.config).to receive(:valkyrie_transition?).and_return(true)
        allow(Hyrax.query_service).to receive(:find_by).with(id: work_id).and_return(valkyrie_work)
      end

      it 'uses Hyrax.query_service.find_by' do
        result = controller_instance.send(:load_curation_concern_for_manifest, work_id)
        expect(result).to eq valkyrie_work
      end
    end

    context 'when valkyrie_transition? is false' do
      let(:af_work) { instance_double('CurateGenericWork', id: work_id) }

      before do
        allow(Hyrax.config).to receive(:valkyrie_transition?).and_return(false)
        allow(CurateGenericWork).to receive(:find).with(work_id).and_return(af_work)
      end

      it 'uses CurateGenericWork.find' do
        result = controller_instance.send(:load_curation_concern_for_manifest, work_id)
        expect(result).to eq af_work
      end
    end
  end

  describe 'Hyrax::CurateGenericWorksController' do
    describe '.curation_concern_type' do
      context 'when valkyrie_transition? is true' do
        before do
          allow(Hyrax.config).to receive(:valkyrie_transition?).and_return(true)
        end

        it 'is set to CurateGenericWorkResource' do
          expect(Hyrax::CurateGenericWorksController.curation_concern_type).to eq CurateGenericWorkResource if Hyrax.config.valkyrie_transition?
        end
      end
    end
  end
end
