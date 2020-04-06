# frozen_string_literal: true
require "rails_helper"
include Warden::Test::Helpers

RSpec.describe "download requests", :clean, type: :request, iiif: true do
  let(:user) { FactoryBot.create(:user) }
  let(:admin) { FactoryBot.create(:admin) }
  let(:public_file_set_id) { "747dr7sqvt-cor" }
  let(:public_low_view_file_set_id) { "955m905qgg-cor" }
  let(:restricted_file_set_id) { "restricted-fileset-id" }
  let(:public_low_view_file_set_attributes) do
    { "id" => public_low_view_file_set_id,
      "has_model_ssim" => "FileSet",
      "visibility_ssi" => "low_res",
      "read_access_group_ssim" => ["low_res"] }
  end
  let(:public_file_set_attributes) do
    { "id" => public_file_set_id,
      "has_model_ssim" => "FileSet",
      "visibility_ssi" => "open",
      "read_access_group_ssim" => ["public"] }
  end
  let(:restricted_file_set_attributes) do
    { "id" => restricted_file_set_id,
      "has_model_ssim" => "FileSet",
      "visibility_ssi" => "private",
      "read_access_group_ssim" => ["private"] }
  end
  before do
    solr = Blacklight.default_index.connection
    solr.add([public_low_view_file_set_attributes,
              public_file_set_attributes,
              restricted_file_set_attributes])
    solr.commit
    allow(Hyrax::DerivativePath).to receive(:derivative_path_for_reference).with(any_args).and_return("#{fixture_path}/balloon.jpeg")
  end

  describe "GET" do
    context "a Public Low View object" do
      context "thumbnail" do
        it "returns a thumbnail for an admin user" do
          login_as admin
          get("/downloads/#{public_low_view_file_set_id}?file=thumbnail", params: { file: :thumbnail, id: public_low_view_file_set_id })
          expect(response.status).to eq 200
        end

        it "returns a thumbnail for a not-logged-in user" do
          get("/downloads/#{public_low_view_file_set_id}?file=thumbnail", params: { file: :thumbnail, id: public_low_view_file_set_id })
          expect(response.status).to eq 200
          expect(response.body).not_to be_empty
        end
      end

      context "full resolution, full size file" do
        it "can download the full size image as an admin user" do
          login_as admin
          get("/downloads/#{public_low_view_file_set_id}", params: { file: :preservation_master_file, id: public_low_view_file_set_id })
          expect(response.status).to eq 200
        end
        it "cannot download the full size image as a non-logged-in-user" do
          get("/downloads/#{public_low_view_file_set_id}", params: { file: :preservation_master_file, id: public_low_view_file_set_id })
          expect(response.status).to eq 401
        end
      end
    end

    context "a Public object" do
      context "thumbnail" do
        it "returns a thumbnail for a logged in user" do
          login_as user
          get("/downloads/#{public_file_set_id}?file=thumbnail", params: { format: :image })
          expect(response.status).to eq 200
        end

        it "returns a thumbnail for a not-logged-in user" do
          get("/downloads/#{public_file_set_id}?file=thumbnail", params: { format: :image })
          expect(response.status).to eq 200
        end
      end
    end

    context "a Restricted object" do
      it "as an admin user, I can download the full size image" do
        login_as admin
        get("/downloads/#{restricted_file_set_id}", params: { file: :preservation_master_file, id: restricted_file_set_id })
        expect(response.status).to eq 200
      end
      it "cannot download the full size image as a non-logged-in-user" do
        get("/downloads/#{restricted_file_set_id}", params: { file: :preservation_master_file, id: restricted_file_set_id })
        expect(response.status).to eq 401
      end
    end

    context "an Emory Low Download object" do
      context "thumbnail" do
        it "returns a thumbnail for an admin user" do
          login_as admin
          get("/downloads/#{public_low_view_file_set_id}?file=thumbnail", params: { file: :thumbnail, id: public_low_view_file_set_id })
          expect(response.status).to eq 200
        end
        xit "does not return a thumbnail for a not-logged-in user" do
          get("/downloads/#{public_low_view_file_set_id}?file=thumbnail", params: { file: :thumbnail, id: public_low_view_file_set_id })
          expect(response.status).to eq 401
          expect(response.body).to be_empty
        end
      end
    end
  end
end
