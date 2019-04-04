require 'rails_helper'

RSpec.describe FileSet do
  describe '#related_files' do
    let!(:f1) { described_class.new }

    context 'when there are no related files' do
      it 'returns an empty array' do
        expect(f1.related_files).to eq []
      end
    end

    context 'when there are related files' do
      let(:parent_work)   { FactoryBot.create(:work_with_files) }
      let(:f1)            { parent_work.file_sets.first }
      let(:f2)            { parent_work.file_sets.last }
      let(:related_files) { f1.reload.related_files }

      it 'returns all files contained in parent work(s) but excludes itself' do
        expect(related_files).to include(f2)
        expect(related_files).not_to include(f1)
      end
    end
  end
end
