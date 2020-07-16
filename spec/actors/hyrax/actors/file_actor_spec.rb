# frozen_string_literal: true
# [Hyrax-overwrite-v3.0.0.pre.rc1]
require 'rails_helper'

RSpec.describe Hyrax::Actors::FileActor, :clean do
  include ActionDispatch::TestProcess
  # commenting out next line because we are not using mocked file anywhere in this test
  # include Hyrax::FactoryHelpers

  let(:user)     { FactoryBot.create(:user) }
  let(:file_set) { FactoryBot.create(:file_set) }
  let(:relation) { :preservation_master_file }
  let(:actor)    { described_class.new(file_set, relation, user) }
  let(:fixture)  { fixture_file_upload('/image.png', 'image/png') }
  let(:huf) { Hyrax::UploadedFile.new(user: user, file_set_uri: file_set.uri, preservation_master_file: fixture) }
  let(:io) { JobIoWrapper.new(file_set_id: file_set.id, user: user, path: fixture.path, relation: relation, preferred: relation) }
  let(:pcdmfile) do
    Hydra::PCDM::File.new.tap do |f|
      f.content = File.open(fixture.path).read
      f.original_name = fixture.original_filename
      f.save!
    end
  end

  context 'relation' do
    let(:relation) { :remastered }
    let(:file_set) do
      FileSetWithExtras.create!(FactoryBot.attributes_for(:file_set)) do |file|
        file.apply_depositor_metadata(user.user_key)
      end
    end

    before do
      class FileSetWithExtras < FileSet
        directly_contains_one :remastered, through: :files, type: ::RDF::URI('http://pcdm.org/use#IntermediateFile'), class_name: 'Hydra::PCDM::File'
      end
    end
    after do
      Object.send(:remove_const, :FileSetWithExtras)
    end
    it 'uses the relation from the actor' do
      expect(CharacterizeJob).not_to receive(:perform_later)
      actor.ingest_file(io)
      expect(CreateDerivativesJob).not_to receive(:perform_later).with(file_set, pcdmfile.id, fixture.path)
      expect(file_set.reload.remastered.mime_type).to eq 'image/png'
    end
  end

  # This test will fail because mime_type method in JobIoWrapper model runs on
  # the `uploader` alias for original_file which is set in the Hyrax::UploadedFile model.
  # However, in our case, we don't have aliases since we have more than one file type.
  # In this test, we create an instance of the JobIoWrapper using `path` method (refer line#16)
  # instead of `uploaded_file` method which requires a file to be an instance of the Hyrax::UploadedFile class

  # it 'uses the provided mime_type' do
  #   allow(fixture).to receive(:content_type).and_return('image/gif')
  #   expect(CharacterizeJob).to receive(:perform_later).with(file_set, String, fixture.path)
  #   actor.ingest_file(io)
  #   expect(file_set.reload.preservation_master_file.mime_type).to eq 'image/gif'
  # end

  context 'with two existing versions from different users' do
    let(:fixture2) { fixture_file_upload('/small_file.txt', 'text/plain') }
    let(:huf2) { Hyrax::UploadedFile.new(user: user2, file_set_uri: file_set.uri, preservation_master_file: fixture2) }
    let(:io2) { JobIoWrapper.new(file_set_id: file_set.id, user: user2, path: fixture2.path, relation: relation) }
    let(:user2) { FactoryBot.create(:user) }
    let(:actor2) { described_class.new(file_set, relation, user2) }
    let(:versions) { file_set.reload.original_file.versions }

    before do
      allow(Hydra::Works::CharacterizationService).to receive(:run).with(any_args)
      actor.ingest_file(io)
      actor2.ingest_file(io2)
    end

    xit 'has two versions' do
      expect(versions.all.count).to eq 2
      # the current version
      expect(Hyrax::VersioningService.latest_version_of(file_set.reload.original_file).label).to eq 'version2'
      expect(file_set.original_file.mime_type).to eq 'text/plain'
      expect(file_set.original_file.content).to eq fixture2.open.read
      # the user for each version
      expect(Hyrax::VersionCommitter.where(version_id: versions.first.uri).pluck(:committer_login)).to eq [user.user_key]
      expect(Hyrax::VersionCommitter.where(version_id: versions.last.uri).pluck(:committer_login)).to eq [user2.user_key]
    end
  end

  describe '#ingest_file' do
    before do
      expect(Hydra::Works::AddFileToFileSet).to receive(:call).with(file_set, io, relation, versioning: false)
      allow(CreateDerivativesJob).to receive(:perform_later).with(file_set, pcdmfile.id, fixture.path)
    end
    it 'when the file is available' do
      allow(file_set).to receive(:save).and_return(true)
      allow(file_set).to receive(relation).and_return(pcdmfile)
      expect(Hyrax::VersioningService).to receive(:create).with(pcdmfile, user)
      expect(CharacterizeJob).to receive(:perform_later).with(file_set, pcdmfile.id, fixture.path)
      actor.ingest_file(io)
    end
    it 'returns false when save fails' do
      allow(file_set).to receive(:save).and_return(false)
      expect(actor.ingest_file(io)).to be_falsey
    end
  end

  # Adds this test to confirm that characterization is only run on pmf by
  # expecting exactly one format_label for the pmf
  context 'with two files for a fileset' do
    let(:relation2) { :intermediate_file }
    let(:actor2) { described_class.new(file_set, relation2, user2) }
    let(:fixture2) { fixture_file_upload('/small_file.txt', 'text/plain') }
    let(:io2) { JobIoWrapper.new(file_set_id: file_set.id, user: user2, path: fixture2.path, relation: relation2) }
    let(:user2) { FactoryBot.create(:user) }
    let(:fits_filename) { 'fits_1.4.0_image_png.xml' }
    let(:fits_response) { IO.read(File.join(fixture_path, fits_filename)) }
    let(:fits_filename2) { 'fits_1.4.0_small_file_txt.xml' }
    let(:fits_response2) { IO.read(File.join(fixture_path, fits_filename2)) }
    let(:hexdigest_value) { "urn:sha256:9f08fe67e102fc94950070cf5de88ba760846516daf2c76a1167c809ec37b37a" }

    it 'characterizes preservation_master_file', perform_enqueued: [CharacterizeJob] do
      allow(Digest::SHA256).to receive_message_chain(:file, :hexdigest, :prepend).and_return(hexdigest_value)
      allow(Hydra::FileCharacterization).to receive(:characterize).and_return(fits_response)
      actor.ingest_file(io)
      allow(Hydra::FileCharacterization).to receive(:characterize).and_return(fits_response2)
      actor2.ingest_file(io2)
      expect(file_set.files.size).to eq 2
      expect(file_set.reload.preservation_master_file.format_label).to eq ["Portable Network Graphics"]
    end
  end

  # TODO: Implement this when working on revert_to method in Hyrax::Actors::FileActor
  # describe '#revert_to' do
  #   let(:revision_id) { 'asdf1234' }

  #   before do
  #     allow(pcdmfile).to receive(:restore_version).with(revision_id)
  #     allow(file_set).to receive(relation).and_return(pcdmfile)
  #     expect(Hyrax::VersioningService).to receive(:create).with(pcdmfile, user)
  #     expect(CharacterizeJob).to receive(:perform_later).with(file_set, pcdmfile.id)
  #   end

  #   it 'reverts to a previous version of a file' do
  #     expect(file_set).not_to receive(:remastered)
  #     expect(actor.relation).to eq(:preservation_master_file)
  #     actor.revert_to(revision_id)
  #   end

  #   describe 'for a different relation' do
  #     let(:relation) { :remastered }

  #     it 'reverts to a previous version of a file' do
  #       expect(actor.relation).to eq(:remastered)
  #       actor.revert_to(revision_id)
  #     end
  #     it 'does not rely on the default relation' do
  #       pending "Hydra::Works::VirusCheck must support other relations: https://github.com/samvera/hyrax/issues/1187"
  #       expect(actor.relation).to eq(:remastered)
  #       expect(file_set).not_to receive(:preservation_master_file)
  #       actor.revert_to(revision_id)
  #     end
  #   end
  # end
end
