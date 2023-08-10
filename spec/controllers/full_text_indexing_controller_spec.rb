# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FullTextIndexingController, type: :controller, clean: true do
  let(:admin) { FactoryBot.create(:admin) }
  let(:work) { FactoryBot.create(:public_generic_work, user: admin) }

  context "when signed in" do
    describe "POST full_text_index" do
      before do
        sign_in admin
      end

      it "queues up compile full text job" do
        expect(CompileFullTextJob).to receive(:perform_later).with(work_id: work.id, user_id: admin.id)
        post :full_text_index, params: { work_id: work.id, user_id: admin.id }, xhr: true
        expect(response).to be_successful
      end
    end
  end

  context "when not signed in" do
    describe "POST full_text_index" do
      it "returns 401" do
        post :full_text_index, params: { work_id: work.id, user_id: admin.id }, xhr: true
        expect(response.code).to eq '401'
      end
    end
  end
end
