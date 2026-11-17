# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AssociateFilesetsWithWorks do
  subject(:associator) { Class.new { include AssociateFilesetsWithWorks }.new }
  let(:page1) { FileSetResource.new(id: Valkyrie::ID.new('page-1')) }
  let(:page2) { FileSetResource.new(id: Valkyrie::ID.new('page-2')) }
  let(:page3) { FileSetResource.new(id: Valkyrie::ID.new('page-3')) }
  let(:work) { CurateGenericWorkResource.new(id: Valkyrie::ID.new('work-1'), deduplication_key: 'MSS1', member_ids:) }
  let(:entries) { [entry, entry, entry] }
  let(:entry) { double('entry', failed?: false, import_attempts: 1) }

  before do
    allow(associator).to receive(:pull_fileset_entries_for_parent).with('MSS1').and_return(entries)
    allow(ReplaceWorkMembersJob).to receive(:perform_now)
  end

  describe '#associate_valkyrie' do
    context 'when the FileSets were attached in the order their jobs finished' do
      let(:member_ids) { [page3.id, page1.id, page2.id] }

      it 'puts them in the order of their CSV rows' do
        associator.associate_valkyrie(work, [page1, page2, page3])

        expect(ReplaceWorkMembersJob).to have_received(:perform_now).with(work, ['page-1', 'page-2', 'page-3'])
      end
    end

    context 'with duplicated members and members from outside the import' do
      let(:member_ids) { [page2.id, Valkyrie::ID.new('earlier-member'), page1.id, page2.id, page3.id] }

      it 'keeps the other members first and drops the duplicates' do
        associator.associate_valkyrie(work, [page1, page2, page3])

        expect(ReplaceWorkMembersJob).to have_received(:perform_now).with(work, ['earlier-member', 'page-1', 'page-2', 'page-3'])
      end
    end

    context 'when the members are already in order' do
      let(:member_ids) { [page1.id, page2.id, page3.id] }

      it 'leaves the work alone' do
        associator.associate_valkyrie(work, [page1, page2, page3])

        expect(ReplaceWorkMembersJob).not_to have_received(:perform_now)
      end
    end

    context 'when a FileSet has not been created yet' do
      let(:member_ids) { [page1.id] }

      it 'waits for it' do
        expect { associator.associate_valkyrie(work, [page1, page2]) }.to raise_error("All FileSetResources haven't been persisted yet")
      end
    end

    context 'when the import gave up on a FileSet' do
      let(:member_ids) { [page3.id, page1.id] }
      let(:given_up) { double('given up entry', failed?: true, import_attempts: 8) }
      let(:entries) { [entry, given_up, entry] }

      it 'orders the FileSets that were created' do
        associator.associate_valkyrie(work, [page1, page3])

        expect(ReplaceWorkMembersJob).to have_received(:perform_now).with(work, ['page-1', 'page-3'])
      end
    end
  end

  describe '#pull_file_set_entries' do
    it 'returns the FileSet entries in the order of their CSV rows' do
      later = double('later entry', id: 12, factory_class: FileSetResource)
      earlier = double('earlier entry', id: 11, factory_class: FileSetResource)
      work_entry = double('work entry', id: 10, factory_class: CurateGenericWorkResource)
      importer = double('importer', entries: [later, work_entry, earlier])

      expect(associator.pull_file_set_entries(importer:)).to eq [earlier, later]
    end
  end
end
