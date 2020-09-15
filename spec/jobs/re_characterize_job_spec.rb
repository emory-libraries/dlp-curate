# frozen_string_literal: true
require 'rails_helper'

RSpec.describe ReCharacterizeJob, :clean do
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
    allow(Hydra::Works::CharacterizationService).to receive(:run).with(file, filename)
    CharacterizeJob.perform_now(file_set, file.id)
  end

  context 'processing' do
    it 'calls the right services and jobs' do
      repository_file = file_set.public_send(:preservation_master_file)

      expect(ReCharacterizationService).to receive(:empty_out_characterization).with(repository_file)
      expect(CharacterizeJob).to receive(:perform_later).with(file_set, repository_file.id, "", user)
      described_class.perform_now(file_set: file_set, user: user)
    end
  end
end
