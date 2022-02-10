# frozen_string_literal: true
require 'rails_helper'

# [Hyrax-overwrite-v3.1.0] The only thing altered in this controller is the allowed params.
RSpec.describe Hyrax::Admin::CollectionTypesController, type: :controller, clean: true do
  routes { Hyrax::Engine.routes }
  let(:valid_attributes) do
    {
      title:                      'Collection type title',
      description:                'Description of collection type',
      nestable:                   true,
      discoverable:               true,
      sharable:                   true,
      brandable:                  true,
      share_applies_to_new_works: true,
      allow_multiple_membership:  true,
      require_membership:         true,
      assigns_workflow:           true,
      assigns_visibility:         true,
      deposit_only_collection:    true
    }
  end
  let(:collection_type) { FactoryBot.create(:collection_type) }
  let(:user) { FactoryBot.create(:admin) }

  context "deposit_only_collection param" do
    it "permits this new attribute to be assigned" do
      sign_in user
      post :create, params: { collection_type: valid_attributes }
      deposit_only_param = controller.send(:collection_type_params)['deposit_only_collection']

      expect(deposit_only_param).to be_truthy
    end
  end
end
