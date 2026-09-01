# frozen_string_literal: true
require 'rails_helper'

RSpec.describe CurateAfIngestJob, :clean, perform_enqueued: [CurateAfIngestJob, CreatePreservationEventJob] do
  let(:user)     { FactoryBot.create(:user) }
  let(:file_set) { FactoryBot.create(:file_set) }
  let(:pmf)      { File.open(fixture_path + '/book_page/0003_preservation_master.tif') }
  let(:inf)      { File.open(fixture_path + '/book_page/0003_intermediate.jp2') }
  let(:tf)       { File.open(fixture_path + '/book_page/0003_transcript.txt') }

  describe '#perform' do
    context 'with multiple file types' do
      let(:uploaded_file) do
        Hyrax::UploadedFile.create(
          user:,
          preservation_master_file: pmf,
          intermediate_file:        inf,
          transcript:               tf
        )
      end

      it 'ingests all file types sequentially into the file set' do
        described_class.perform_now(file_set, uploaded_file, user, :preservation_master_file)
        file_set.reload

        expect(file_set.preservation_master_file).to be_present
        expect(file_set.intermediate_file).to be_present
        expect(file_set.transcript_file).to be_present
      end

      it 'creates preservation events for each file' do
        described_class.perform_now(file_set, uploaded_file, user, :preservation_master_file)
        file_set.reload

        details = file_set.preservation_event.pluck(:event_details).flatten.compact
        expect(details).to include(a_string_matching(/preservation_master.*submitted for preservation storage/))
        expect(details).to include(a_string_matching(/intermediate.*submitted for preservation storage/))
        expect(details).to include(a_string_matching(/transcript.*submitted for preservation storage/))
      end

      it 'triggers characterization only for the preservation master' do
        expect(CharacterizeJob).to receive(:perform_later).once
        described_class.perform_now(file_set, uploaded_file, user, :preservation_master_file)
      end
    end

    context 'with only a preservation master file' do
      let(:uploaded_file) do
        Hyrax::UploadedFile.create(user:, preservation_master_file: pmf)
      end

      it 'ingests only the preservation master' do
        described_class.perform_now(file_set, uploaded_file, user, :preservation_master_file)
        file_set.reload

        expect(file_set.preservation_master_file).to be_present
        expect(file_set.intermediate_file).to be_nil
      end
    end

    context 'when a file type fails' do
      let(:uploaded_file) do
        Hyrax::UploadedFile.create(
          user:,
          preservation_master_file: pmf,
          intermediate_file:        inf
        )
      end

      it 'records a failure preservation event' do
        allow_any_instance_of(Hyrax::Actors::FileActor)
          .to receive(:ingest_file)
          .and_return(false)

        described_class.perform_now(file_set, uploaded_file, user, :preservation_master_file)
        file_set.reload

        outcomes = file_set.preservation_event.pluck(:outcome).flatten.compact
        expect(outcomes).to include('Failure')
      end
    end
  end

  describe 'retry behavior' do
    let(:uploaded_file) do
      Hyrax::UploadedFile.create(user:, preservation_master_file: pmf)
    end

    it 'retries on Ldp::HttpError' do
      expect(described_class.rescue_handlers).to include(
        a_collection_including('Ldp::HttpError')
      )
    end

    it 'defines fatal LDP patterns including NullPointerException' do
      expect(described_class::FATAL_LDP_PATTERNS).to include('java.lang.NullPointerException')
      expect(described_class::FATAL_LDP_PATTERNS).to include('org.modeshape.jcr.value.binary.BinaryStoreException')
    end
  end
end
