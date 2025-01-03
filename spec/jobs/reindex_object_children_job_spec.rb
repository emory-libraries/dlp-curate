# frozen_string_literal: true
require 'rails_helper'

RSpec.describe ReindexObjectChildrenJob, :clean do
  let(:work) { FactoryBot.create(:public_generic_work) }
  let(:job_instance) { described_class.new }
  let(:file_set) { FactoryBot.create(:file_set, read_groups: ['public']) }
  let(:pmf) { File.open(fixture_path + '/book_page/0003_preservation_master.tif') }

  before { job_instance.instance_variable_set(:@id, work.id) }

  context '#object_children' do
    it 'logs an empty array with object with no member ids' do
      expect(job_instance.object_children).to eq([])
    end

    describe 'object with member ids' do
      it 'logs an array of objects' do
        Hydra::Works::AddFileToFileSet.call(file_set, pmf, :preservation_master_file)
        work.ordered_members << file_set
        work.save!

        expect(job_instance.object_children).not_to eq([])
      end
    end
  end

  context '#pull_child_objects' do
    it 'returns an empty array when given an empty array' do
      expect(job_instance.pull_child_objects([])).to eq([])
    end

    it 'returns an array of objects when given an array of ids' do
      expect(job_instance.pull_child_objects([file_set.id])).not_to eq([])
    end
  end
end
