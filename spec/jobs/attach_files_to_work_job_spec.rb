# [Hyrax-overwrite] Attaching multiple files to single fileset
# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AttachFilesToWorkJob, perform_enqueued: [AttachFilesToWorkJob] do
  let(:pmf) { File.open(fixture_path + '/book_page/0003_preservation_master.tif') }
  let(:inf) { File.open(fixture_path + '/book_page/0003_intermediate.jp2') }
  let(:sf)  { File.open(fixture_path + '/book_page/0003_service.jpg') }
  let(:et)  { File.open(fixture_path + '/book_page/0003_extracted_text.pos') }
  let(:tf)  { File.open(fixture_path + '/book_page/0003_transcript.txt') }
  let(:uploaded_file1) do
    FactoryBot.build(:uploaded_file,
                     file: 'Example title',
                     preservation_master_file: pmf,
                     intermediate_file: inf,
                     service_file: sf,
                     extracted_text: et,
                     transcript: tf,
                     fileset_use: 'primary')
  end
  let(:uploaded_file2) do
    FactoryBot.build(:uploaded_file,
                     preservation_master_file: pmf,
                     service_file: sf,
                     transcript: tf,
                     fileset_use: 'supplementary')
  end
  let(:generic_work) { FactoryBot.create(:public_generic_work) }
  let(:user) { FactoryBot.create(:user) }

  shared_examples 'a file attacher', perform_enqueued: [AttachFilesToWorkJob, IngestJob] do
    it 'attaches files, copies visibility and permissions and updates the uploaded files' do
      expect(CharacterizeJob).to receive(:perform_later).once
      described_class.perform_now(generic_work, [uploaded_file1])
      generic_work.reload
      expect(generic_work.file_sets.first.title).to eq ['Example title']
      expect(generic_work.file_sets.first.pcdm_use).to eq 'primary'
      expect(generic_work.file_sets.first.files.size).to eq 5
      expect(generic_work.file_sets.first.extracted_text).to eq nil
      expect(generic_work.file_sets.first.extracted.file_name).to eq ['0003_extracted_text.pos']
      expect(generic_work.file_sets.map(&:visibility)).to all(eq 'open')
      expect(uploaded_file1.reload.file_set_uri).not_to be_nil
      expect(ImportUrlJob).not_to have_been_enqueued
    end
  end

  context "sets fileset name" do
    it_behaves_like 'a file attacher' do
      it 'sets fileset name as preservation_master_file name when fileset name is not present' do
        described_class.perform_now(generic_work, [uploaded_file2])

        expect(generic_work.file_sets.first.title).to eq ['0003_preservation_master.tif']
        expect(generic_work.file_sets.first.pcdm_use).to eq 'supplementary'
        expect(generic_work.file_sets.first.files.size).to eq 3
      end
    end
  end

  context "with uploaded files on the filesystem" do
    before do
      generic_work.permissions.build(name: 'userz@bbb.ddd', type: 'person', access: 'edit')
      generic_work.save
    end
    it_behaves_like 'a file attacher' do
      it 'records the depositor(s) in edit_users' do
        expect(generic_work.file_sets.map(&:edit_users)).to all(match_array([generic_work.depositor, 'userz@bbb.ddd']))
      end

      describe 'with existing files' do
        let(:file_set)       { FactoryBot.create(:file_set) }
        let(:uploaded_file1) { FactoryBot.build(:uploaded_file, file: pmf, file_set_uri: 'http://example.com/file_set') }

        it 'skips files that already have a FileSet' do
          expect { described_class.perform_now(generic_work, [uploaded_file1, uploaded_file2]) }
            .to change { generic_work.file_sets.count }.to eq 1
        end
      end
    end
  end

  context "deposited on behalf of another user" do
    before do
      generic_work.on_behalf_of = user.user_key
      generic_work.save
    end
    it_behaves_like 'a file attacher' do
      it 'records the depositor(s) in edit_users' do
        expect(generic_work.file_sets.map(&:edit_users)).to all(match_array([user.user_key]))
      end
    end
  end

  context "deposited as 'Yourself' selected in on behalf of list" do
    before do
      generic_work.on_behalf_of = ''
      generic_work.save
    end
    it_behaves_like 'a file attacher' do
      it 'records the depositor(s) in edit_users' do
        expect(generic_work.file_sets.map(&:edit_users)).to all(match_array([generic_work.depositor]))
      end
    end
  end
end
