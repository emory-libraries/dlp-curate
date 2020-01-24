# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work CurateGenericWork`
require 'rails_helper'

RSpec.describe Hyrax::CurateGenericWorksController do
  let(:user) { FactoryBot.create(:user) }
  let(:work) { FactoryBot.create(:public_generic_work, id: '888889') }
  let(:solr_document) { SolrDocument.new(attributes) }
  let(:manifest_file) { IO.read(fixture_path + '/manifest_fixture.json') }
  before { sign_in user }
  let(:attributes) do
    { "id" => '888889',
      "title_tesim" => ['foo', 'bar'],
      "human_readable_type_tesim" => ["Curate Generic Work"],
      "has_model_ssim" => ["CurateGenericWork"],
      "date_created_tesim" => ['an unformatted date'],
      "date_modified_dtsi" => "2019-11-11T18:20:32Z",
      "depositor_tesim" => user.uid }
  end
  describe "GET #manifest" do
    it "returns http success" do
      get :manifest, params: { id: work.id, format: 'json' }
      expect(response).to have_http_status(:success)
    end

    context "generates manifest" do
      before do
        allow(SolrDocument).to receive(:find).and_return(solr_document)
      end

      it "saves manifest file" do
        get :manifest, params: { id: work.id, format: 'json' }
        expect(response.body).to include(work.id)
        expect(File).to exist("./tmp/2019-11-11_18-20-32_888889")
        get :manifest, params: { id: work.id, format: 'json' }
        expect(File.open("./tmp/2019-11-11_18-20-32_888889").read). to eq manifest_file
      end
    end
  end
end
