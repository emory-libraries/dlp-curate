# frozen_string_literal: true
# [Hyrax-overwrite-v3.3.0]
require 'rails_helper'

RSpec.describe CharacterizeJob, :clean do
  let(:file_set_id) { 'abc12345' }
  let(:filename)    { Rails.root.join('tmp', 'uploads', 'ab', 'c1', '23', '45', 'abc12345', 'picture.png').to_s }
  let(:file_set) do
    FileSet.new(id: file_set_id).tap do |fs|
      allow(fs).to receive(:preservation_master_file).and_return(file)
      allow(fs).to receive(:update_index)
    end
  end
  let(:user) { 'bob' }

  let(:file) do
    Hydra::PCDM::File.new.tap do |f|
      f.content = 'foo'
      f.original_name = 'picture.png'
      f.save!
      allow(f).to receive(:save!)
    end
  end

  before do
    allow(FileSet).to receive(:find).with(file_set_id).and_return(file_set)
    allow(Hydra::Works::CharacterizationService).to receive(:run).with(file, filename, {}, user)
    # commenting out because we are doing this in file_actor and not characterize_job
    # allow(CreateDerivativesJob).to receive(:perform_later).with(file_set, file.id, filename)
  end

  context 'with valid filepath param' do
    let(:filename) { File.join(fixture_path, 'world.png') }

    it 'skips Hyrax::WorkingDirectory' do
      expect(Hyrax::WorkingDirectory).not_to receive(:find_or_retrieve)
      expect(Hydra::Works::CharacterizationService).to receive(:run).with(file, filename, {}, user)
      described_class.perform_now(file_set, file.id, filename, user)
    end
  end

  context 'when the characterization proxy content is present' do
    it 'runs Hydra::Works::CharacterizationService and creates a CreateDerivativesJob' do
      expect(Hydra::Works::CharacterizationService).to receive(:run).with(file, filename, {}, user)
      expect(file).to receive(:save!)
      expect(file_set).to receive(:update_index)
      # commenting out because we are doing this in file_actor and not characterize_job
      # expect(CreateDerivativesJob).to receive(:perform_later).with(file_set, file.id, filename)
      described_class.perform_now(file_set, file.id, "", user)
    end
  end

  context 'when the characterization proxy content is absent' do
    before { allow(file_set).to receive(:characterization_proxy?).and_return(false) }
    it 'raises an error' do
      expect { described_class.perform_now(file_set, file.id) }.to raise_error(StandardError, /preservation_master_file was not found/)
    end
  end

  context "when performed" do
    before do
      described_class.perform_now(file_set, file.id, "", user)
    end
    it "adds a new preservation event for fileset characterization" do
      expect(file_set.preservation_event.first.event_type).to eq ['Characterization']
      expect(file_set.preservation_event.first.outcome).to eq ['Success']
      expect(file_set.preservation_event.first.event_details).to eq ['preservation_master_file: picture.png - Technical metadata extracted from file, format identified, and file validated']
      expect(file_set.preservation_event.first.initiating_user).to eq [user]
    end
  end
end
