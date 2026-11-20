# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Curate::CollectionSharingBackfillService do
  subject(:service) { described_class.new(logger: Logger.new(nil), dry_run:, collection_id:) }
  let(:dry_run) { false }
  let(:collection_id) { nil }
  let(:valkyrie_query_service) { double('fedora query service') }
  let(:valkyrie_work) { CurateGenericWorkResource.new(id: Valkyrie::ID.new('valkyrie-work')) }
  let(:af_work) { instance_double(CurateGenericWork) }

  before do
    allow(Hyrax::SolrService).to receive(:query).and_return([{ 'id' => 'valkyrie-work' }, { 'id' => 'af-work' }, { 'id' => 'broken-work' }])
    allow(Valkyrie::MetadataAdapter).to receive(:find).with(:fedora_metadata).and_return(double(query_service: valkyrie_query_service))
    allow(valkyrie_query_service).to receive(:find_by).with(id: 'valkyrie-work').and_return(valkyrie_work)
    allow(valkyrie_query_service).to receive(:find_by).with(id: 'af-work').and_raise(Valkyrie::Persistence::ObjectNotFoundError)
    allow(valkyrie_query_service).to receive(:find_by).with(id: 'broken-work').and_raise(StandardError, 'Fedora unavailable')
    allow(CurateGenericWork).to receive(:find).with('af-work').and_return(af_work)
    allow(Curate::CollectionSharingService).to receive(:share_with_saved).with(valkyrie_work, dry_run:).and_return([valkyrie_work])
    allow(Curate::CollectionSharingService).to receive(:share_with_saved).with(af_work, dry_run:).and_return([])
  end

  it 'shares collections with the works in them, loading works not yet migrated through ActiveFedora' do
    expect(service.backfill).to eq(shared: 1, unchanged: 1, errored: 1)
    expect(Hyrax::SolrService).to have_received(:query).with('has_model_ssim:CurateGenericWork AND member_of_collection_ids_ssim:*', fl: 'id', rows: 1_000_000)
  end

  context 'with DRY_RUN' do
    let(:dry_run) { true }

    it 'passes the dry run on' do
      service.backfill

      expect(Curate::CollectionSharingService).to have_received(:share_with_saved).with(valkyrie_work, dry_run: true)
    end
  end

  context 'with a COLLECTION_ID' do
    let(:collection_id) { 'peel-collection' }

    it "only backfills that collection's works" do
      service.backfill

      expect(Hyrax::SolrService).to have_received(:query)
        .with('has_model_ssim:CurateGenericWork AND member_of_collection_ids_ssim:peel\\-collection', fl: 'id', rows: 1_000_000)
    end
  end
end
