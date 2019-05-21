# [Hyrax-overwrite] Attaching multiple files to single fileset
require 'rails_helper'

RSpec.describe AttachFilesToWorkJob, perform_enqueued: [AttachFilesToWorkJob] do
  let(:file1) { File.open(fixture_path + '/world.png') }
  let(:file2) { File.open(fixture_path + '/image.jp2') }
  let(:uploaded_file1) { FactoryBot.build(:uploaded_file, file: file1, file_type: :original_file) }
  let(:uploaded_file2) { FactoryBot.build(:uploaded_file, file: file2, file_type: :preservation_master_file) }
  let(:uploaded_file3) { FactoryBot.build(:uploaded_file, file: file2, file_type: :service_file) }
  let(:generic_work) { FactoryBot.create(:public_generic_work) }
  let(:user) { FactoryBot.create(:user) }

  shared_examples 'a file attacher', perform_enqueued: [AttachFilesToWorkJob, IngestJob] do
    it 'attaches files, copies visibility and permissions and updates the uploaded files' do
      expect(CharacterizeJob).to receive(:perform_later).exactly(3).times
      described_class.perform_now(generic_work, [uploaded_file1, uploaded_file2, uploaded_file3])
      generic_work.reload
      expect(generic_work.file_sets.first.files.size).to eq 3
      expect(generic_work.file_sets.map(&:visibility)).to all(eq 'open')
      expect(uploaded_file1.reload.file_set_uri).not_to be_nil
      expect(ImportUrlJob).not_to have_been_enqueued
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
        let(:uploaded_file1) { FactoryBot.build(:uploaded_file, file: file1, file_set_uri: 'http://example.com/file_set') }

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
