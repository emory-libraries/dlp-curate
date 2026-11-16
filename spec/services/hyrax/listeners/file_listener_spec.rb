# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Hyrax::Listeners::FileListener do
  subject(:listener) { described_class.new }
  let(:event) { Dry::Events::Event.new('file.uploaded', metadata:) }
  let(:file_set) { FileSetResource.new(id: Valkyrie::ID.new('fs-1')) }
  let(:metadata) do
    Hyrax::FileMetadata.new(id: Valkyrie::ID.new('fm-1'), file_set_id: file_set.id, pcdm_use: [pcdm_use], file_identifier:)
  end
  let(:file_identifier) { Valkyrie::ID.new('fedora://fs-1/intermediate') }

  before do
    allow(ValkyrieCharacterizationJob).to receive(:perform_later)
    allow(ValkyrieCreateDerivativesJob).to receive(:perform_later)
    allow(Hyrax.query_service).to receive(:find_by).with(id: file_set.id).and_return(file_set)
  end

  describe '#on_file_uploaded' do
    context 'with a preservation master file' do
      let(:pcdm_use) { Hyrax::FileMetadata::Use::ORIGINAL_FILE }

      it 'characterizes it without creating derivatives' do
        listener.on_file_uploaded(event)

        expect(ValkyrieCharacterizationJob).to have_received(:perform_later).with('fm-1')
        expect(ValkyrieCreateDerivativesJob).not_to have_received(:perform_later)
      end
    end

    context 'with an intermediate file' do
      let(:pcdm_use) { Hyrax::FileMetadata::Use::INTERMEDIATE_FILE }

      it 'characterizes it and creates derivatives from it' do
        listener.on_file_uploaded(event)

        expect(ValkyrieCharacterizationJob).to have_received(:perform_later).with('fm-1')
        expect(ValkyrieCreateDerivativesJob).to have_received(:perform_later).with('fs-1', 'fm-1')
      end
    end

    context 'with a derivative saved to the derivatives storage' do
      let(:pcdm_use) { Hyrax::FileMetadata::Use::THUMBNAIL_IMAGE }
      let(:file_identifier) do
        Valkyrie::ID.new("disk://#{Hyrax.config.derivatives_storage_adapter.base_path}/fs-1-thumbnail.jpeg")
      end

      it 'neither characterizes it nor creates derivatives from it' do
        listener.on_file_uploaded(event)

        expect(ValkyrieCharacterizationJob).not_to have_received(:perform_later)
        expect(ValkyrieCreateDerivativesJob).not_to have_received(:perform_later)
      end
    end
  end
end
