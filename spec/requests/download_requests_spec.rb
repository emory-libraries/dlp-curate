
# frozen_string_literal: true
require "rails_helper"
include Warden::Test::Helpers

RSpec.describe "download requests", :clean, type: :request, iiif: true do
  let(:user) { FactoryBot.create(:user) }
  # This currently points to a real object in Max's development environment
  let(:work_id) { "26663xsj41-cor" }
  let(:file_set_id) { "747dr7sqvt-cor" }

  before do
    solr = Blacklight.default_index.connection
    solr.add([work_attributes, file_set_attributes])
    solr.commit
  end

  describe "GET thumbnail" do
    context "with a Public object" do
      let(:work_attributes) do
        { "id" => work_id,
          "hasRelatedMediaFragment_ssim" => [file_set_id],
          "hasRelatedImage_ssim" => [file_set_id],
          "thumbnail_path_ss" => "/downloads/#{file_set_id}?file=thumbnail",
          "member_ids_ssim" => [file_set_id],
          "file_set_ids_ssim" => [file_set_id],
          "visibility_ssi" => "open",
          "read_access_group_ssim" => ["public"] }
      end
      let(:file_set_attributes) do
        { "id" => file_set_id,
          "has_model_ssim" => "FileSet",
          "member_ids_ssim" => [file_set_id],
          "file_set_ids_ssim" => [file_set_id],
          "visibility_ssi" => "open",
          "read_access_group_ssim" => ["public"] }
      end

      context "a request for a thumbnail" do
        before do
          allow(Hyrax::DerivativePath).to receive(:derivative_path_for_reference).with(any_args).and_return("#{fixture_path}/balloon.jpeg")
        end
        it "returns a thumbnail for a logged in user" do
          login_as user
          get("/downloads/#{file_set_id}?file=thumbnail", params: { format: :image })
          expect(response.status).to eq 200
        end

        it "returns a thumbnail for a not-logged-in user" do
          get("/downloads/#{file_set_id}?file=thumbnail")
          expect(response.status).to eq 200
        end
      end
    end
  end
end
