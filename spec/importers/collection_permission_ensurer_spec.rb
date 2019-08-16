# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CollectionPermissionEnsurer, :clean do
  let(:collection) { Collection.new }
  let(:ensurer) { described_class.new(collection: collection, access_permissions: ['manage', 'deposit']) }

  it 'sets the access permssions specified in the permissons array' do
    ensurer
    expect(Hyrax::PermissionTemplateAccess.where(agent_id: 'admin').count).to eq(2)
  end
end
