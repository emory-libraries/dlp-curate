# [Hyrax-overwrite-v3.0.0.pre.rc1] Attaching multiple files to single fileset
# frozen_string_literal: true
require 'rails_helper'

RSpec.describe CompileFullTextJob, :clean, perform_enqueued: [CompileFullTextJob, AttachFilesToWorkJob, IngestJob] do
  let(:pmf) { File.open(fixture_path + '/book_page/0003_preservation_master.tif') }
  let(:tf)  { File.open(fixture_path + '/book_page/0003_transcript.txt') }
  let(:uploaded_file) do
    FactoryBot.build(:uploaded_file,
                     file:                     'Example title',
                     preservation_master_file: pmf,
                     transcript:               tf,
                     fileset_use:              'primary')
  end
  let(:generic_work) { FactoryBot.create(:public_generic_work) }
  let(:user)         { FactoryBot.create(:user) }

  it 'compiles full text into one file at the volume level' do
    AttachFilesToWorkJob.perform_now(generic_work, [uploaded_file])
    described_class.perform_now(work_id: generic_work.id, user_id: user.id)
    generic_work.reload
    expect(generic_work.file_sets.count).to eq(2)
    full_text_file_set = generic_work.file_sets.last
    expect(full_text_file_set.parent).to eq(generic_work)
    expect(full_text_file_set.label).to eq "Full Text Data - #{generic_work.id}"
    expect(full_text_file_set.files.first.content).to include("The idea of publishing cheap one-volume novels is a good one")
  end
end
