# frozen_string_literal: true
# [Hyrax-override-hyrax-v5.2.0] spec/jobs/create_derivatives_job_spec.rb .
#   Adds in Logger and additional tests for bad or missing file.
require 'rails_helper'

RSpec.describe CreateDerivativesJob, :clean do
  around do |example|
    ffmpeg_enabled = Hyrax.config.enable_ffmpeg
    Hyrax.config.enable_ffmpeg = true
    example.run
    Hyrax.config.enable_ffmpeg = ffmpeg_enabled
  end
  let(:logger) { instance_double(Logger) }

  context "filepath parameter" do
    let(:file_set) { FactoryBot.create(:file_set) }

    let(:file) do
      Hydra::PCDM::File.new do |f|
        f.content = File.open(File.join(fixture_path, 'world.png'))
        f.original_name = 'world.png'
        f.mime_type = 'image/png'
      end
    end

    before do
      file_set.original_file = file
      file_set.save!
    end

    describe 'with valid filepath param' do
      let(:filename) { File.join(fixture_path, 'world.png') }

      it 'skips Hyrax::WorkingDirectory.copy_repository_resource_to_working_directory' do
        expect(Hyrax::WorkingDirectory).not_to receive(:copy_repository_resource_to_working_directory)
        expect(Hydra::Derivatives::ImageDerivatives).to receive(:create)
        described_class.perform_now(file_set, file.id, filename)
      end
    end

    describe 'with no filepath param' do
      let(:filename) { nil }

      it 'Uses Hyrax::WorkingDirectory.copy_repository_resource_to_working_directory to pull the repo file' do
        expect(Hyrax::WorkingDirectory).to receive(:copy_repository_resource_to_working_directory)
        expect(Hydra::Derivatives::ImageDerivatives).to receive(:create)
        described_class.perform_now(file_set, file.id, filename)
      end
    end
  end

  context "with an audio file" do
    let(:id)       { '123' }
    let(:file_set) { FileSet.new }

    let(:file) do
      Hydra::PCDM::File.new.tap do |f|
        f.content = 'foo'
        f.original_name = 'picture.png'
        f.save!
      end
    end

    before do
      allow(FileSet).to receive(:find).with(id).and_return(file_set)
      allow(file_set).to receive(:id).and_return(id)
      allow(file_set).to receive(:mime_type).and_return('audio/x-wav')
      allow(Logger).to receive(:new).and_return(logger)
    end

    context "with a file name" do
      it 'calls create_derivatives and save on a file set' do
        expect(Hydra::Derivatives::AudioDerivatives).to receive(:create)
        expect(file_set).to receive(:reload)
        expect(file_set).to receive(:update_index)
        expect(logger).to receive(:info)
        described_class.perform_now(file_set, file.id)
      end
    end

    context 'with a parent object' do
      before do
        allow(file_set).to receive(:parent).and_return(parent)
        # Stub out the actual derivative creation
        allow(file_set).to receive(:create_derivatives)
      end

      context 'when the file_set is the thumbnail of the parent' do
        let(:parent) { CurateGenericWork.new(thumbnail_id: id) }

        it 'updates the index of the parent object' do
          expect(file_set).to receive(:reload)
          expect(parent).to receive(:update_index)
          expect(logger).to receive(:info)
          described_class.perform_now(file_set, file.id)
        end
      end

      context "when the file_set isn't the parent's thumbnail" do
        let(:parent) { CurateGenericWork.new }

        it "doesn't update the parent's index" do
          expect(file_set).to receive(:reload)
          expect(parent).not_to receive(:update_index)
          expect(logger).to receive(:info)
          described_class.perform_now(file_set, file.id)
        end
      end
    end
  end

  context "with a pdf file" do
    let(:file_set) { FactoryBot.create(:file_set) }

    let(:file) do
      Hydra::PCDM::File.new do |f|
        f.content = File.open(File.join(fixture_path, "/hyrax_test4.pdf"))
        f.original_name = 'test.pdf'
        f.mime_type = 'application/pdf'
      end
    end

    before do
      file_set.preservation_master_file = file
      file_set.save!
    end

    it "runs a full text extract" do
      expect(Hydra::Derivatives::PdfDerivatives).to receive(:create)
        .with(/test\.pdf/, outputs: [{ label:  :thumbnail,
                                       format: 'jpg',
                                       size:   '338x493',
                                       url:    String,
                                       layer:  0 }])
      expect(Hydra::Derivatives::FullTextExtract).not_to receive(:create)
      described_class.perform_now(file_set, file.id)
    end
  end

  context "with a bad/missing file" do
    let(:id)       { 'abc123' }
    let(:file_set) { FactoryBot.create(:file_set) }
    let(:filename) { Hyrax::WorkingDirectory.find_or_retrieve(file.id, file_set.id, nil) }

    let(:file) do
      Hydra::PCDM::File.new.tap do |f|
        f.content = 'foo'
        f.original_name = 'picture.png'
        f.save!
      end
    end

    before do
      allow(file_set).to receive(:id).and_return(id)
      allow(file_set).to receive(:create_derivatives).and_raise(MiniMagick::Error)
      allow(Logger).to receive(:new).and_return(logger)
    end

    it "logs info and warn" do
      expect(logger).to receive(:info).with("CreateDerivativesJob for #{filename} started at #{DateTime.current}")
      expect(logger).to receive(:warn).with("Error occurred in CreateDerivativesJob for #{filename}")
      described_class.perform_now(file_set, file.id)
    end
  end
end
