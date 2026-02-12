# frozen_string_literal: true
require 'rails_helper'

RSpec.describe CurateDownloadsController, :clean do
  describe '#pdf_for_viewer' do
    let(:user) { FactoryBot.create(:user) }
    let(:file_set) { FactoryBot.create(:file_set, user:, title: ['Some title']) }
    let(:file) { File.open(fixture_path + '/sample-file.pdf') }
    before { Hydra::Works::AddFileToFileSet.call(file_set, file, :preservation_master_file) }

    context 'when no one is signed in' do
      it 'delivers the file' do
        get :pdf_for_viewer, params: { id: file_set }
        expect(response.body).to eq file_set.preservation_master_file.content
      end

      describe 'when file is not a pdf' do
        let(:file) { File.open(fixture_path + '/image.png') }

        it 'raises an error' do
          expect do
            get :pdf_for_viewer, params: { id: file_set }
          end.to raise_error Hyrax::ObjectNotFoundError
        end
      end
    end
  end
end
