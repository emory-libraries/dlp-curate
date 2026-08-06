# frozen_string_literal: true
require 'rails_helper'

RSpec.describe ReindexObjectChildrenJob, :clean do
  let(:work) { FactoryBot.create(:public_generic_work) }
  let(:file_set) { FactoryBot.create(:file_set, read_groups: ['public']) }
  let(:pmf) { File.open(fixture_path + '/book_page/0003_preservation_master.tif') }

  before do
    allow(Hyrax.config).to receive(:valkyrie_transition?).and_return(false)
  end

  describe '#perform' do
    context 'when the work has no children' do
      it 'completes without error' do
        expect { described_class.perform_now(work.id) }.not_to raise_error
      end
    end

    context 'when the work has children' do
      before do
        Hydra::Works::AddFileToFileSet.call(file_set, pmf, :preservation_master_file)
        work.ordered_members << file_set
        work.save!
      end

      it 'reindexes child objects' do
        expect(file_set).to receive(:update_index)
        allow(ActiveFedora::Base).to receive(:find).and_call_original
        allow(ActiveFedora::Base).to receive(:find).with(file_set.id).and_return(file_set)

        described_class.perform_now(work.id)
      end
    end
  end
end
