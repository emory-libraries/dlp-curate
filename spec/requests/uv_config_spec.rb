# frozen_string_literal: true
require "rails_helper"

RSpec.describe "UvConfiguration requests", :clean, type: :request do
  before do
    solr = Blacklight.default_index.connection
    solr.add([
               work_with_public_visibility,
               work_with_public_low_view_visibility,
               work_with_emory_high_visibility,
               work_with_emory_low_visibility
             ])
    solr.commit
  end

  let(:emory_high_work_id) { '111-321' }
  let(:public_work_id) { '222-321' }
  let(:public_low_view_work_id) { '333-321' }
  let(:emory_low_work_id) { '444-321' }

  let(:work_with_emory_high_visibility) do
    WORK_WITH_EMORY_HIGH_VISIBILITY
  end

  let(:work_with_public_visibility) do
    WORK_WITH_PUBLIC_VISIBILITY
  end

  let(:work_with_public_low_view_visibility) do
    WORK_WITH_PUBLIC_LOW_VIEW_VISIBILITY
  end

  let(:work_with_emory_low_visibility) do
    WORK_WITH_EMORY_LOW_VISIBILITY
  end

  describe "GET /uv/config/:id" do
    it "pulls a Universal Viewer manifest for the resource" do
      get "/uv/config/#{public_work_id}", params: { format: :json }

      expect(response.status).to eq 200
      expect(response.body).not_to be_empty
      expect(response.content_length).to be > 0
      expect(response.content_type).to eq "application/json"

      response_values = JSON.parse(response.body)
      expect(response_values).to include "modules"
      expect(response_values["modules"]["pagingHeaderPanel"]["options"]).to include "pagingToggleEnabled" => true
      expect(response_values["modules"]["footerPanel"]).to include "options"
      expect(response_values["modules"]["footerPanel"]["options"]).to include(
        "shareEnabled" => true,
        "downloadEnabled" => true,
        "fullscreenEnabled" => true
      )
    end

    it "responds with downloads disabled for a work with 'Public Low View' visibility" do
      get "/uv/config/#{public_low_view_work_id}", params: { format: :json }

      expect(response.status).to eq 200
      expect(response.body).not_to be_empty
      expect(response.content_length).to be > 0
      expect(response.content_type).to eq "application/json"

      response_values = JSON.parse(response.body)
      expect(response_values).to include "modules"
      expect(response_values["modules"]["pagingHeaderPanel"]["options"]).to include "pagingToggleEnabled" => true
      expect(response_values["modules"]["footerPanel"]).to include "options"
      expect(response_values["modules"]["footerPanel"]["options"]).to include(
        "shareEnabled" => false,
        "downloadEnabled" => false,
        "fullscreenEnabled" => false
      )
    end

    context "when the resource does not exist" do
      xit "responds with a 404 status code" do
        get "/uv/config/nonexistent", params: { format: :json }

        expect(response.status).to eq 404
      end
    end

    it "responds with the configuration with downloads enabled for a work with 'Public' visibility" do
      get "/uv/config/#{public_work_id}", params: { format: :json }

      expect(response.status).to eq 200
      expect(response.body).not_to be_empty
      expect(response.content_length).to be > 0
      expect(response.content_type).to eq "application/json"

      response_values = JSON.parse(response.body)
      expect(response_values).to include "modules"
      expect(response_values["modules"]["pagingHeaderPanel"]["options"]).to include "pagingToggleEnabled" => true
      expect(response_values["modules"]).to include "footerPanel"
      expect(response_values["modules"]["footerPanel"]).to include "options"
      expect(response_values["modules"]["footerPanel"]["options"]).to include(
        "shareEnabled" => true,
        "downloadEnabled" => true,
        "fullscreenEnabled" => true
      )
    end

    it "responds with downloads enabled for a work with 'Emory High Download' visibility" do
      get "/uv/config/#{emory_high_work_id}", params: { format: :json }

      expect(response.status).to eq 200
      expect(response.body).not_to be_empty
      expect(response.content_length).to be > 0
      expect(response.content_type).to eq "application/json"

      response_values = JSON.parse(response.body)
      expect(response_values).to include "modules"
      expect(response_values["modules"]["footerPanel"]).to include "options"
      expect(response_values["modules"]["footerPanel"]["options"]).to include(
        "shareEnabled" => true,
        "downloadEnabled" => true,
        "fullscreenEnabled" => true
      )
    end

    it "responds with downloads enabled for a work with 'Emory Low Download' visibility" do
      get "/uv/config/#{emory_low_work_id}", params: { format: :json }

      expect(response.status).to eq 200
      expect(response.body).not_to be_empty
      expect(response.content_length).to be > 0
      expect(response.content_type).to eq "application/json"

      response_values = JSON.parse(response.body)
      expect(response_values).to include "modules"
      expect(response_values["modules"]["footerPanel"]).to include "options"
      expect(response_values["modules"]["footerPanel"]["options"]).to include(
        "shareEnabled" => true,
        "downloadEnabled" => true,
        "fullscreenEnabled" => true
      )
      expect(response_values["modules"]["downloadDialogue"]).to include("options", "content")
      expect(response_values["modules"]["downloadDialogue"]["options"]).to include(
        "currentViewDisabledPercentage" => 0,
        "confinedImageSize" => 100_000
      )
      expect(response_values["modules"]["downloadDialogue"]["content"]).to include("wholeImageHighRes")
    end
  end
end
