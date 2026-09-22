# frozen_string_literal: true
require 'rails_helper'

RSpec.describe ManifestValkyrieCompat do
  describe '.find_work' do
    let(:id) { 'work-id' }
    let(:work) { instance_double(CurateGenericWork) }

    context 'when valkyrie_transition is false' do
      before { allow(Hyrax.config).to receive(:valkyrie_transition?).and_return(false) }

      it 'loads the ActiveFedora work' do
        allow(CurateGenericWork).to receive(:find).with(id).and_return(work)

        expect(described_class.find_work(id)).to eq(work)
      end
    end

    context 'when valkyrie_transition is true' do
      let(:resource) { Hyrax::Work.new(id:) }

      before { allow(Hyrax.config).to receive(:valkyrie_transition?).and_return(true) }

      it 'loads the work through the Valkyrie query service' do
        allow(Hyrax.query_service).to receive(:find_by).with(id:).and_return(resource)

        expect(described_class.find_work(id)).to eq(resource)
      end

      it 'falls back to ActiveFedora when the Valkyrie lookup fails' do
        allow(Hyrax.query_service).to receive(:find_by).and_raise(Valkyrie::Persistence::ObjectNotFoundError)
        allow(CurateGenericWork).to receive(:find).with(id).and_return(work)

        expect(described_class.find_work(id)).to eq(work)
      end
    end
  end

  describe '.find_file_set' do
    let(:id) { 'fileset-id' }
    let(:file_set) { instance_double(FileSet) }

    context 'when valkyrie_transition is false' do
      before { allow(Hyrax.config).to receive(:valkyrie_transition?).and_return(false) }

      it 'loads the ActiveFedora file set' do
        allow(FileSet).to receive(:find).with(id).and_return(file_set)

        expect(described_class.find_file_set(id)).to eq(file_set)
      end
    end

    context 'when valkyrie_transition is true' do
      let(:resource) { Hyrax::FileSet.new(id:) }

      before { allow(Hyrax.config).to receive(:valkyrie_transition?).and_return(true) }

      it 'loads the file set through the Valkyrie query service' do
        allow(Hyrax.query_service).to receive(:find_by).with(id:).and_return(resource)

        expect(described_class.find_file_set(id)).to eq(resource)
      end

      it 'falls back to ActiveFedora when the Valkyrie lookup fails' do
        allow(Hyrax.query_service).to receive(:find_by).and_raise(Valkyrie::Persistence::ObjectNotFoundError)
        allow(FileSet).to receive(:find).with(id).and_return(file_set)

        expect(described_class.find_file_set(id)).to eq(file_set)
      end
    end
  end

  describe '.file_set_member_ids' do
    context 'with an ActiveFedora work' do
      let(:work) { instance_double(CurateGenericWork, ordered_member_ids: ['fs-1', 'fs-2', 'child-1'], child_work_ids: ['child-1']) }

      it 'subtracts child work ids from ordered members' do
        expect(described_class.file_set_member_ids(work)).to eq(['fs-1', 'fs-2'])
      end
    end

    context 'with a Valkyrie work' do
      let(:work) { Hyrax::Work.new(id: 'val-work', member_ids: ['fs-1', 'fs-2', 'child-1']) }

      it 'subtracts child work ids from member_ids' do
        allow(Hyrax.custom_queries).to receive(:find_child_work_ids).with(resource: work).and_return(['child-1'])

        expect(described_class.file_set_member_ids(work)).to eq(['fs-1', 'fs-2'])
      end
    end
  end

  describe '.file_set_mime_type' do
    it 'reads mime_type from an ActiveFedora file set' do
      file_set = instance_double(FileSet, mime_type: 'image/tiff')

      expect(described_class.file_set_mime_type(file_set)).to eq('image/tiff')
    end

    it 'reads mime_type from a Valkyrie original file' do
      original = instance_double(Hyrax::FileMetadata, mime_type: 'image/jpeg')
      file_set = Hyrax::FileSet.new(id: 'fs-1')
      allow(file_set).to receive(:original_file).and_return(original)

      expect(described_class.file_set_mime_type(file_set)).to eq('image/jpeg')
    end
  end

  describe '.file_set_visibility' do
    it 'reads visibility from an ActiveFedora file set' do
      file_set = instance_double(FileSet, visibility: 'open')

      expect(described_class.file_set_visibility(file_set)).to eq('open')
    end

    it 'reads visibility through VisibilityReader for a Valkyrie file set' do
      file_set = Hyrax::FileSet.new(id: 'fs-1')
      reader = instance_double(Hyrax::VisibilityReader, read: 'restricted')
      allow(Hyrax::VisibilityReader).to receive(:new).with(resource: file_set).and_return(reader)

      expect(described_class.file_set_visibility(file_set)).to eq('restricted')
    end
  end

  describe '.file_set_dimensions' do
    it 'returns ActiveFedora original_file width and height' do
      original = double(width: 100, height: 200)
      file_set = instance_double(FileSet, original_file: original)

      expect(described_class.file_set_dimensions(file_set)).to eq([100, 200])
    end

    it 'unwraps Valkyrie width and height sets' do
      original = instance_double(Hyrax::FileMetadata, width: ['640'], height: ['480'])
      file_set = Hyrax::FileSet.new(id: 'fs-1')
      allow(file_set).to receive(:original_file).and_return(original)

      expect(described_class.file_set_dimensions(file_set)).to eq(['640', '480'])
    end
  end

  describe '.preferred_file_id' do
    it 'returns the preferred binary id for an ActiveFedora file set' do
      binary = double(id: 'fs-1/files/abc')
      file_set = instance_double(FileSet, id: 'fs-1', preferred_file: :service_file)
      allow(file_set).to receive(:pulled_service_file).and_return(binary)

      expect(described_class.preferred_file_id(file_set)).to eq('fs-1/files/abc')
    end

    it 'returns the file set id for a Valkyrie file set' do
      file_set = Hyrax::FileSet.new(id: 'fs-1')

      expect(described_class.preferred_file_id(file_set)).to eq('fs-1')
    end
  end

  describe '.checksum_urn' do
    it 'returns unknown when no file is present' do
      expect(described_class.checksum_urn(nil)).to eq('urn:sha1:unknown')
    end

    it 'reads checksum.value from an ActiveFedora preferred file' do
      checksum = double(value: 'urn:sha1:abc123')
      binary = double(checksum:)
      file_set = instance_double(FileSet, preferred_file: :preservation_master_file)
      allow(file_set).to receive(:pulled_preservation_master_file).and_return(binary)

      expect(described_class.checksum_urn(file_set)).to eq('urn:sha1:abc123')
    end

    it 'reads checksum from a Valkyrie original file' do
      checksum = double(value: 'urn:sha1:def456')
      original = instance_double(Hyrax::FileMetadata, checksum: [checksum])
      file_set = Hyrax::FileSet.new(id: 'fs-1')
      allow(file_set).to receive(:original_file).and_return(original)

      expect(described_class.checksum_urn(file_set)).to eq('urn:sha1:def456')
    end
  end
end
