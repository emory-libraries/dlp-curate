# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hyrax::UploadedFile, type: :model do
  let(:user)          { FactoryBot.build(:user) }
  let(:file_set)      { FactoryBot.create(:file_set) }
  let(:hyrax_resource) { Hyrax::Resource.new(id: 'test_id_123') }
  let(:uploaded_file) { described_class.new(user: user) }

  describe '#add_file_set!' do
    context 'when fileset is ActiveFedora::Base' do
      it 'sets uri to fileset uri' do
        uploaded_file.add_file_set!(file_set)
        uploaded_file.reload
        expect(uploaded_file.file_set_uri).to eq file_set.uri
      end
    end

    context 'when fileset is Hyrax::Resource' do
      it 'sets uri to fileset id' do
        uploaded_file.add_file_set!(hyrax_resource)
        uploaded_file.reload
        expect(uploaded_file.file_set_uri).to eq hyrax_resource.id
      end
    end
  end

  describe '#uploader' do
    context 'when a file does not exist' do
      it 'returns nil' do
        expect(uploaded_file.uploader).to be_nil
      end
    end

    context 'when a file exists' do
      let(:pmf) { File.open(fixture_path + '/book_page/0003_preservation_master.tif') }
      let(:uploaded_file) { described_class.new(user: user, preservation_master_file: pmf) }

      it 'returns the file' do
        expect(uploaded_file.uploader).to eq(uploaded_file.preservation_master_file)
      end
    end
  end
end
