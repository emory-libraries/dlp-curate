# frozen_string_literal: true
# [Hyrax-overwrite-v3.3.0]
# We have removed json_response tests from here since we are
# no longer rendering json in our create method
require 'rails_helper'

RSpec.describe Hyrax::FixityChecksController do
  routes { Hyrax::Engine.routes }
  let(:user) { FactoryBot.create(:user) }
  let(:file_set) { FactoryBot.create(:file_set, user: user) }
  let(:binary) { File.open(fixture_path + '/world.png') }
  let(:file) { Hydra::Derivatives::IoDecorator.new(binary, 'image/png', 'world.png') }

  before { Hydra::Works::UploadFileToFileSet.call(file_set, file) }

  context "when signed in" do
    describe "POST create" do
      before do
        sign_in user
        post :create, params: { file_set_id: file_set }, xhr: true
      end

      it "returns result and redirects to file_set page" do
        expect(response).to be_successful
        expect(response.redirect_url).to include "/concern/file_sets/#{file_set.id}"
      end
    end
  end

  context "when not signed in" do
    describe "POST create" do
      it "returns json with the result" do
        post :create, params: { file_set_id: file_set }, xhr: true
        expect(response.code).to eq '401'
      end
    end
  end
end
