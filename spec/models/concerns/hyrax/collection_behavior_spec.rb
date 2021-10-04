# frozen_string_literal: true

# [Hyrax-overwrite-v3.1.0]
require 'rails_helper'

RSpec.describe Hyrax::CollectionBehavior, clean: true do
  let(:collection) { FactoryBot.create(:collection_lw) }
  let(:work) { FactoryBot.create(:public_generic_work) }

  describe "#destroy" do
    it "removes the collection id from associated members" do
      Hyrax::Collections::CollectionMemberService.add_members_by_ids(collection_id:  collection.id,
                                                                     new_member_ids: [work.id],
                                                                     user:           nil)
      collection.save

      collection_via_query = Hyrax.query_service.find_by_alternate_identifier(alternate_identifier: collection.id, use_valkyrie: false)

      expect { collection_via_query.destroy }
        .to change { Hyrax.query_service.find_by(id: work.id).member_of_collection_ids }
        .from([collection.id])
        .to([])
    end
  end
end
