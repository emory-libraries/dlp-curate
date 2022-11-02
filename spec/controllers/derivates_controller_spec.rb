# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DerivativesController, type: :controller, clean: true do
  let(:user) { FactoryBot.create(:user) }
  let(:file_set) { FactoryBot.create(:file_set, user: user) }

  context "when signed in" do
    describe "POST clean_up" do
      before do
        sign_in user
      end

      it "queues up fileset cleanup job" do
        expect(FileSetCleanUpJob).to receive(:perform_later).with(file_set.id)
        post :clean_up, params: { file_set_id: file_set }, xhr: true
        expect(response).to be_successful
      end
    end
  end

  context "when not signed in" do
    describe "POST clean_up" do
      it "returns 401" do
        post :clean_up, params: { file_set_id: file_set }, xhr: true
        expect(response.code).to eq '401'
      end
    end
  end
end
