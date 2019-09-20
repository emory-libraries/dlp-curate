# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CollectionPermissionEnsurer, :clean do
  let(:collection) { FactoryBot.create(:collection_lw) }
  let(:ensurer) { described_class.new(collection: collection, access_permissions: { 'manage' => ["admin", "rose_manager"], 'deposit' => ["admin", "rose_depositor"], 'view' => ["rose_viewer"] }) }

  it 'sets the access permssions specified in the permissons array' do
    allow(Role).to receive(:exists?).and_return(true)
    ensurer
    expect(Hyrax::PermissionTemplateAccess.where(agent_id: 'admin').count).to eq(2)
    expect(Hyrax::PermissionTemplateAccess.where(agent_id: 'rose_manager').count).to eq(1)
    expect(Hyrax::PermissionTemplateAccess.where(agent_id: 'rose_depositor').count).to eq(1)
    expect(collection.edit_groups).to eq(["admin", "rose_manager"])
    expect(collection.read_groups).to eq(["public", "rose_viewer"])
  end
end
