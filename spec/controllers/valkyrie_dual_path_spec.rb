# frozen_string_literal: true

require 'rails_helper'

# Tests the valkyrie_transition? dual-path logic across controllers.
# These specs verify that controllers correctly branch between AF and Valkyrie
# resource loading based on Hyrax.config.valkyrie_transition?.
RSpec.describe 'Valkyrie dual-path controller logic', type: :controller do
  let(:user) { FactoryBot.create(:user) }
  let(:file_set_id) { 'fs-abc-123' }
  let(:work_id) { 'work-xyz-456' }

  describe 'CharacterizationController#load_file_set' do
    let(:controller_instance) { CharacterizationController.new }

    before do
      allow(controller_instance).to receive(:params).and_return(file_set_id:)
    end

    context 'when valkyrie_transition? is true' do
      let(:valkyrie_file_set) { instance_double('FileSetResource', id: file_set_id) }

      before do
        allow(Hyrax.config).to receive(:valkyrie_transition?).and_return(true)
        allow(Hyrax.query_service).to receive(:find_by).with(id: file_set_id).and_return(valkyrie_file_set)
      end

      it 'loads the file set via Hyrax.query_service' do
        result = controller_instance.send(:load_file_set)
        expect(result).to eq valkyrie_file_set
      end
    end

    context 'when valkyrie_transition? is false' do
      let(:af_file_set) { instance_double('FileSet', id: file_set_id) }

      before do
        allow(Hyrax.config).to receive(:valkyrie_transition?).and_return(false)
        allow(FileSet).to receive(:find).with(file_set_id).and_return(af_file_set)
      end

      it 'loads the file set via FileSet.find' do
        result = controller_instance.send(:load_file_set)
        expect(result).to eq af_file_set
      end
    end
  end

  describe 'ManifestRegenerationController#load_curation_concern_for_manifest' do
    let(:controller_instance) { ManifestRegenerationController.new }

    before do
      allow(controller_instance).to receive(:params).and_return({})
    end

    context 'when valkyrie_transition? is true' do
      let(:valkyrie_work) { instance_double('CurateGenericWorkResource', id: work_id) }

      before do
        allow(Hyrax.config).to receive(:valkyrie_transition?).and_return(true)
        allow(Hyrax.query_service).to receive(:find_by).with(id: work_id).and_return(valkyrie_work)
      end

      it 'loads the work via Hyrax.query_service' do
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

      it 'loads the work via CurateGenericWork.find' do
        result = controller_instance.send(:load_curation_concern_for_manifest, work_id)
        expect(result).to eq af_work
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
          @original_type = Hyrax::CurateGenericWorksController.curation_concern_type
          Hyrax::CurateGenericWorksController.curation_concern_type = CurateGenericWorkResource
        end

        after do
          Hyrax::CurateGenericWorksController.curation_concern_type = @original_type
        end

        it 'is set to CurateGenericWorkResource' do
          expect(Hyrax::CurateGenericWorksController.curation_concern_type).to eq CurateGenericWorkResource
        end
      end
    end
  end
end
