# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FullTextIndexingController, type: :controller, clean: true do
  let(:admin) { FactoryBot.create(:admin) }
  let!(:work) { FactoryBot.create(:public_generic_work, user: admin) }

  context "when signed in" do
    describe "POST full_text_index" do
      before { sign_in admin }

      it "queues up compile full text job" do
        expect(CompileFullTextJob).to receive(:perform_later).with(work_id: work.id, user_id: admin.id)

        post :full_text_index, params: { work_id: work.id, user_id: admin.id }, xhr: true

        expect(response).to be_successful
      end

      it "queues up compile full text and reindex jobs" do
        expect(CompileFullTextJob).to receive(:perform_later).with(work_id: work.id, user_id: admin.id)
        expect(ReindexObjectChildrenJob).to receive(:perform_later).with(work.id)

        post :full_text_index_with_pages, params: { work_id: work.id, user_id: admin.id }, xhr: true

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

    describe "POST full_text_index_with_pages" do
      it "returns 401" do
        post :full_text_index_with_pages, params: { work_id: work.id, user_id: admin.id }, xhr: true

        expect(response.code).to eq '401'
      end
    end
  end
end
