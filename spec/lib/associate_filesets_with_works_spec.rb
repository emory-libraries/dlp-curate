# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AssociateFilesetsWithWorks do
  subject(:associator) { Class.new { include AssociateFilesetsWithWorks }.new }
  let(:file_set) { FileSetResource.new(id: Valkyrie::ID.new('fs-1')) }
  let(:work) { CurateGenericWorkResource.new(id: Valkyrie::ID.new('work-1'), deduplication_key: 'MSS1', member_ids:) }

  before do
    allow(associator).to receive(:pull_fileset_entries_for_parent).with('MSS1').and_return([double('entry')])
    allow(Hyrax.persister).to receive(:save) { |resource:| resource }
    allow(Hyrax.index_adapter).to receive(:save)
  end

  describe '#associate_valkyrie' do
    context 'when the importer already attached the FileSet' do
      let(:member_ids) { [file_set.id] }

      it 'does not add it to the work again' do
        associator.associate_valkyrie(work, [file_set])

        expect(work.member_ids).to eq [file_set.id]
        expect(Hyrax.persister).not_to have_received(:save)
      end
    end

    context 'when the FileSet is not a member yet' do
      let(:member_ids) { [] }

      it 'adds it to the work once' do
        associator.associate_valkyrie(work, [file_set])

        expect(Hyrax.persister).to have_received(:save) do |resource:|
          expect(resource.member_ids).to eq [file_set.id]
        end
        expect(Hyrax.index_adapter).to have_received(:save)
      end
    end
  end
end
