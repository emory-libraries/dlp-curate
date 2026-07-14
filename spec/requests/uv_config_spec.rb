# frozen_string_literal: true
require "rails_helper"

RSpec.describe "UvConfiguration requests", :clean, type: :request do
  let(:emory_high_work_id) { '111-321' }
  let(:public_work_id) { '222-321' }
  let(:public_low_view_work_id) { '333-321' }
  let(:emory_low_work_id) { '444-321' }
  let(:work_with_emory_high_visibility) { WORK_WITH_EMORY_HIGH_VISIBILITY }
  let(:work_with_public_visibility) { WORK_WITH_PUBLIC_VISIBILITY }
  let(:work_with_public_low_view_visibility) { WORK_WITH_PUBLIC_LOW_VIEW_VISIBILITY }
  let(:work_with_emory_low_visibility) { WORK_WITH_EMORY_LOW_VISIBILITY }
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

  describe "GET /uv/config/:id" do
    it "pulls a Universal Viewer manifest for the resource" do
      get "/uv/config/#{public_work_id}", params: { format: :json }
      response_values = JSON.parse(response.body)

      test_responsiveness
      test_common_response_values(response_values)
      test_paging_toggle_enabled(response_values)
      test_footer_panel_options(response_values, true, true, true)
    end

    it "responds with downloads disabled for a work with 'Public Low View' visibility" do
      get "/uv/config/#{public_low_view_work_id}", params: { format: :json }
      response_values = JSON.parse(response.body)
      test_responsiveness
      test_common_response_values(response_values)
      test_paging_toggle_enabled(response_values)
      test_footer_panel_options(response_values, false, false, false)
    end

    context "when the resource does not exist" do
      xit "responds with a 404 status code" do
        get "/uv/config/nonexistent", params: { format: :json }

        expect(response.status).to eq 404
      end
    end

    it "responds with the configuration with downloads enabled for a work with 'Public' visibility" do
      get "/uv/config/#{public_work_id}", params: { format: :json }
      response_values = JSON.parse(response.body)
      test_responsiveness
      test_common_response_values(response_values)
      test_paging_toggle_enabled(response_values)
      expect(response_values["modules"]).to include "footerPanel"
      test_footer_panel_options(response_values, true, true, true)
    end

    it "responds with downloads enabled for a work with 'Emory High Download' visibility" do
      get "/uv/config/#{emory_high_work_id}", params: { format: :json }
      response_values = JSON.parse(response.body)
      test_responsiveness
      test_common_response_values(response_values)
      test_footer_panel_options(response_values, true, true, true)
    end

    it "responds with downloads enabled for a work with 'Emory Low Download' visibility" do
      get "/uv/config/#{emory_low_work_id}", params: { format: :json }
      response_values = JSON.parse(response.body)
      test_responsiveness
      test_common_response_values(response_values)
      test_footer_panel_options(response_values, true, true, true)
      expect(response_values["modules"]["downloadDialogue"]).to include("options", "content")
      expect(response_values["modules"]["downloadDialogue"]["options"]).to include(
        "currentViewDisabledPercentage" => 0,
        "confinedImageSize" => 100_000
      )
      expect(response_values["modules"]["downloadDialogue"]["content"]).to include("wholeImageHighRes")
    end
  end

  def test_responsiveness
    expect(response.status).to eq 200
    expect(response.body).not_to be_empty
    expect(response.content_length).to be > 0
    expect(response.content_type).to include "application/json"
  end

  def test_common_response_values(response_values)
    expect(response_values).to include 'modules'
    expect(response_values['modules']['footerPanel']).to include 'options'
  end

  def test_footer_panel_options(response_values, share_enabled, download_enabled, fullscreen_enabled)
    expect(response_values['modules']['footerPanel']['options']).to include(
      'shareEnabled' => share_enabled,
      'downloadEnabled' => download_enabled,
      'fullscreenEnabled' => fullscreen_enabled
    )
  end

  def test_paging_toggle_enabled(response_values)
    expect(response_values['modules']['pagingHeaderPanel']['options']).to include 'pagingToggleEnabled' => true
  end
end
