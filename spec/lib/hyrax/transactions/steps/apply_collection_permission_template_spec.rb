# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('lib', 'hyrax', 'transactions', 'steps', 'apply_collection_permission_template')

RSpec.describe Hyrax::Transactions::Steps::ApplyCollectionPermissionTemplate do
  subject(:step) { described_class.new }
  let(:work) { CurateGenericWorkResource.new(title: ['A work']) }

  it "applies the collection's sharing to the new work" do
    allow(Curate::CollectionSharingService).to receive(:apply).with(work).and_return(true)

    expect(step.call(work)).to be_success
    expect(Curate::CollectionSharingService).to have_received(:apply).with(work)
  end

  it 'succeeds when no collection sharing applies' do
    allow(Curate::CollectionSharingService).to receive(:apply).with(work).and_return(false)

    expect(step.call(work).value!).to eq work
  end

  it 'fails the transaction when the sharing cannot be applied' do
    allow(Curate::CollectionSharingService).to receive(:apply).and_raise(StandardError, 'database unavailable')

    result = step.call(work)

    expect(result).to be_failure
    expect(result.failure.first).to include('database unavailable')
  end
end
