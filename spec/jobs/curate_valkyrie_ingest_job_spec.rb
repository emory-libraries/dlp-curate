# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CurateValkyrieIngestJob do
  let(:job) { described_class.new }
  let(:user) { instance_double('User') }
  let(:file_set) { instance_double('FileSetResource', id: Valkyrie::ID.new('fs-123')) }

  let(:preservation_uploader) { instance_double('CarrierWave::Uploader::Base') }
  let(:intermediate_uploader) { instance_double('CarrierWave::Uploader::Base') }
  let(:service_uploader) { instance_double('CarrierWave::Uploader::Base') }
  let(:extracted_text_uploader) { instance_double('CarrierWave::Uploader::Base') }
  let(:transcript_uploader) { instance_double('CarrierWave::Uploader::Base') }

  let(:carrier_wave_file) { instance_double('CarrierWave::SanitizedFile', original_filename: 'test.tif', to_file: file_io) }
  let(:file_io) { instance_double('File') }

  let(:uploaded_file) do
    instance_double(
      'Hyrax::UploadedFile',
      file_set_uri:             'fs-123',
      user:,
      preservation_master_file: preservation_uploader,
      intermediate_file:        nil,
      service_file:             nil,
      extracted_text:           nil,
      transcript:               nil
    )
  end

  before do
    allow(Hyrax.query_service).to receive(:find_by)
      .with(id: Valkyrie::ID.new('fs-123'))
      .and_return(file_set)
  end

  describe '#perform' do
    context 'with only preservation_master_file' do
      before do
        allow(preservation_uploader).to receive(:blank?).and_return(false)
        allow(preservation_uploader).to receive(:present?).and_return(true)
        allow(preservation_uploader).to receive(:file).and_return(carrier_wave_file)
      end

      it 'uploads the preservation master with ORIGINAL_FILE use' do
        expect(Hyrax::ValkyrieUpload).to receive(:file).with(
          io:               file_io,
          filename:         'test.tif',
          file_set:,
          use:              Hyrax::FileMetadata::Use::ORIGINAL_FILE,
          user:,
          skip_derivatives: false
        )

        job.perform(uploaded_file)
      end
    end

    context 'with service_file present (preferred for derivatives)' do
      let(:service_carrier) { instance_double('CarrierWave::SanitizedFile', original_filename: 'service.jpg', to_file: file_io) }
      let(:uploaded_file) do
        instance_double(
          'Hyrax::UploadedFile',
          file_set_uri:             'fs-123',
          user:,
          preservation_master_file: preservation_uploader,
          intermediate_file:        nil,
          service_file:             service_uploader,
          extracted_text:           nil,
          transcript:               nil
        )
      end

      before do
        allow(preservation_uploader).to receive(:blank?).and_return(false)
        allow(preservation_uploader).to receive(:present?).and_return(true)
        allow(preservation_uploader).to receive(:file).and_return(carrier_wave_file)
        allow(service_uploader).to receive(:blank?).and_return(false)
        allow(service_uploader).to receive(:present?).and_return(true)
        allow(service_uploader).to receive(:file).and_return(service_carrier)
      end

      it 'uploads preservation_master with skip_derivatives: true' do
        expect(Hyrax::ValkyrieUpload).to receive(:file).with(
          hash_including(
            use:              Hyrax::FileMetadata::Use::ORIGINAL_FILE,
            skip_derivatives: true
          )
        )
        allow(Hyrax::ValkyrieUpload).to receive(:file).with(
          hash_including(use: Hyrax::FileMetadata::Use::SERVICE_FILE)
        )

        job.perform(uploaded_file)
      end

      it 'uploads service_file with skip_derivatives: false' do
        allow(Hyrax::ValkyrieUpload).to receive(:file).with(
          hash_including(use: Hyrax::FileMetadata::Use::ORIGINAL_FILE)
        )
        expect(Hyrax::ValkyrieUpload).to receive(:file).with(
          hash_including(
            use:              Hyrax::FileMetadata::Use::SERVICE_FILE,
            skip_derivatives: false
          )
        )

        job.perform(uploaded_file)
      end
    end

    context 'with intermediate_file present (preferred when no service_file)' do
      let(:intermediate_carrier) { instance_double('CarrierWave::SanitizedFile', original_filename: 'intermediate.tif', to_file: file_io) }
      let(:uploaded_file) do
        instance_double(
          'Hyrax::UploadedFile',
          file_set_uri:             'fs-123',
          user:,
          preservation_master_file: preservation_uploader,
          intermediate_file:        intermediate_uploader,
          service_file:             nil,
          extracted_text:           nil,
          transcript:               nil
        )
      end

      before do
        allow(preservation_uploader).to receive(:blank?).and_return(false)
        allow(preservation_uploader).to receive(:present?).and_return(true)
        allow(preservation_uploader).to receive(:file).and_return(carrier_wave_file)
        allow(intermediate_uploader).to receive(:blank?).and_return(false)
        allow(intermediate_uploader).to receive(:present?).and_return(true)
        allow(intermediate_uploader).to receive(:file).and_return(intermediate_carrier)
      end

      it 'uploads preservation_master with skip_derivatives: true' do
        expect(Hyrax::ValkyrieUpload).to receive(:file).with(
          hash_including(
            use:              Hyrax::FileMetadata::Use::ORIGINAL_FILE,
            skip_derivatives: true
          )
        )
        allow(Hyrax::ValkyrieUpload).to receive(:file).with(
          hash_including(use: Hyrax::FileMetadata::Use::INTERMEDIATE_FILE)
        )

        job.perform(uploaded_file)
      end

      it 'uploads intermediate_file with skip_derivatives: false' do
        allow(Hyrax::ValkyrieUpload).to receive(:file).with(
          hash_including(use: Hyrax::FileMetadata::Use::ORIGINAL_FILE)
        )
        expect(Hyrax::ValkyrieUpload).to receive(:file).with(
          hash_including(
            use:              Hyrax::FileMetadata::Use::INTERMEDIATE_FILE,
            skip_derivatives: false
          )
        )

        job.perform(uploaded_file)
      end
    end

    context 'with all file types present' do
      let(:all_carrier) { instance_double('CarrierWave::SanitizedFile', original_filename: 'file.dat', to_file: file_io) }
      let(:uploaded_file) do
        instance_double(
          'Hyrax::UploadedFile',
          file_set_uri:             'fs-123',
          user:,
          preservation_master_file: preservation_uploader,
          intermediate_file:        intermediate_uploader,
          service_file:             service_uploader,
          extracted_text:           extracted_text_uploader,
          transcript:               transcript_uploader
        )
      end

      before do
        [preservation_uploader, intermediate_uploader, service_uploader,
         extracted_text_uploader, transcript_uploader].each do |uploader|
          allow(uploader).to receive(:blank?).and_return(false)
          allow(uploader).to receive(:present?).and_return(true)
          allow(uploader).to receive(:file).and_return(all_carrier)
        end
      end

      it 'uploads all five file types' do
        expect(Hyrax::ValkyrieUpload).to receive(:file).exactly(5).times
        job.perform(uploaded_file)
      end

      it 'only generates derivatives for service_file (preferred)' do
        expect(Hyrax::ValkyrieUpload).to receive(:file)
          .with(hash_including(use: Hyrax::FileMetadata::Use::SERVICE_FILE, skip_derivatives: false))
        expect(Hyrax::ValkyrieUpload).to receive(:file)
          .with(hash_including(use: Hyrax::FileMetadata::Use::ORIGINAL_FILE, skip_derivatives: true))
        expect(Hyrax::ValkyrieUpload).to receive(:file)
          .with(hash_including(use: Hyrax::FileMetadata::Use::INTERMEDIATE_FILE, skip_derivatives: true))
        expect(Hyrax::ValkyrieUpload).to receive(:file)
          .with(hash_including(use: Hyrax::FileMetadata::Use::EXTRACTED_TEXT, skip_derivatives: true))
        expect(Hyrax::ValkyrieUpload).to receive(:file)
          .with(hash_including(use: Hyrax::FileMetadata::Use::TRANSCRIPT, skip_derivatives: true))

        job.perform(uploaded_file)
      end
    end

    context 'when an uploader is blank' do
      let(:uploaded_file) do
        instance_double(
          'Hyrax::UploadedFile',
          file_set_uri:             'fs-123',
          user:,
          preservation_master_file: nil,
          intermediate_file:        nil,
          service_file:             nil,
          extracted_text:           nil,
          transcript:               nil
        )
      end

      it 'does not upload any files' do
        expect(Hyrax::ValkyrieUpload).not_to receive(:file)
        job.perform(uploaded_file)
      end
    end
  end

  describe 'FILE_TYPE_TO_USE constant' do
    it 'maps preservation_master_file to ORIGINAL_FILE' do
      expect(described_class::FILE_TYPE_TO_USE[:preservation_master_file]).to eq Hyrax::FileMetadata::Use::ORIGINAL_FILE
    end

    it 'maps intermediate_file to INTERMEDIATE_FILE' do
      expect(described_class::FILE_TYPE_TO_USE[:intermediate_file]).to eq Hyrax::FileMetadata::Use::INTERMEDIATE_FILE
    end

    it 'maps service_file to SERVICE_FILE' do
      expect(described_class::FILE_TYPE_TO_USE[:service_file]).to eq Hyrax::FileMetadata::Use::SERVICE_FILE
    end

    it 'maps extracted_text to EXTRACTED_TEXT' do
      expect(described_class::FILE_TYPE_TO_USE[:extracted_text]).to eq Hyrax::FileMetadata::Use::EXTRACTED_TEXT
    end

    it 'maps transcript to TRANSCRIPT' do
      expect(described_class::FILE_TYPE_TO_USE[:transcript]).to eq Hyrax::FileMetadata::Use::TRANSCRIPT
    end
  end

  describe 'queue' do
    it 'uses the ingest queue' do
      expect(described_class.new.queue_name).to eq Hyrax.config.ingest_queue_name.to_s
    end
  end
end
