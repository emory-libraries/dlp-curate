# frozen_string_literal: true
require 'rails_helper'

RSpec.describe TransferWorksJob, :clean do
  let(:import_col) { FactoryBot.create(:collection_lw) }
  let(:true_col)   { FactoryBot.create(:collection_lw) }
  let(:work)       { FactoryBot.create(:public_generic_work) }

  before do
    work.member_of_collections << import_col
    work.save!
  end

  after do
    FileUtils.rm('tmp/stackprof-curate.dump')
  end

  it 'transfers work from import collection to true collection' do
    expect(import_col.member_works).to include(work)
    described_class.perform_now(import_col.id, true_col.id)
    expect(File).to exist('tmp/stackprof-curate.dump')
    expect(import_col.member_works.count).to eq 0
    expect(import_col.member_works).not_to include(work)
    expect(true_col.member_works.count).to eq 1
    expect(true_col.member_works).to include(work)
  end
end
