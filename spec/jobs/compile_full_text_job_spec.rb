# [Hyrax-overwrite-v3.0.0.pre.rc1] Attaching multiple files to single fileset
# frozen_string_literal: true
require 'rails_helper'

RSpec.describe CompileFullTextJob, :clean, perform_enqueued: [CompileFullTextJob, AttachFilesToWorkJob, IngestJob] do
  let!(:uploaded_file_1) do
    FactoryBot.build(:uploaded_file,
                     file:                     'Page 1',
                     preservation_master_file: File.open(fixture_path + '/full_text_data/page_1_pmf.tif'),
                     transcript:               File.open(fixture_path + '/full_text_data/page_1_transcript.txt'),
                     fileset_use:              'primary')
  end

  let!(:uploaded_file_2) do
    FactoryBot.build(:uploaded_file,
                     file:                     'Page 2',
                     preservation_master_file: File.open(fixture_path + '/full_text_data/page_2_pmf.tif'),
                     transcript:               File.open(fixture_path + '/full_text_data/page_2_transcript.txt'),
                     fileset_use:              'primary')
  end

  let(:generic_work) { FactoryBot.create(:public_generic_work) }
  let(:user)         { FactoryBot.create(:user) }

  it 'compiles full text into one file at the volume level' do
    AttachFilesToWorkJob.perform_now(generic_work, [uploaded_file_1, uploaded_file_2])
    described_class.perform_now(work_id: generic_work.id, user_id: user.id)
    generic_work.reload
    expect(generic_work.file_sets.count).to eq(3)
    full_text_file_set = generic_work.file_sets.last
    expect(full_text_file_set.parent).to eq(generic_work)
    expect(full_text_file_set.label).to eq "Full Text Data - #{generic_work.id}"
    expected_text = "\nThis is page 1 of a transcript file used to test compiling full text data.\nThis is page 2 of a transcript file used to test compiling full text data.\n"
    expect(full_text_file_set.files.first.content).to eq(expected_text)
  end
end
