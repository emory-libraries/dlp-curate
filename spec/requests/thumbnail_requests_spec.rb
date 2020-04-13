# frozen_string_literal: true
require "rails_helper"
include Warden::Test::Helpers

RSpec.describe "download requests", :clean, type: :request, iiif: true do
  let(:user) { FactoryBot.create(:user) }
  let(:admin) { FactoryBot.create(:admin) }
  let(:cookie_name) { "bearer_token" }
  let(:encrypted_cookie_value) { "BE0F7323469F3E7DF86CF9CA95B8ADD5D17753DA4F00BB67F2A9E8EC93E6A370" }
  let(:non_reading_room_ip) { '198.51.100.255' }
  let(:reading_room_ip) { '192.0.0.255' }
  let(:public_file_set_id) { "747dr7sqvt-cor" }
  let(:emory_low_file_set_id) { "emory-low-cor" }
  let(:public_low_view_file_set_id) { "955m905qgg-cor" }
  let(:restricted_file_set_id) { "restricted-fileset-id" }
  let(:emory_high_file_set_id) { "emory-high-cor" }
  let(:rose_high_view_file_set_id) { "rose-high-cor" }
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
  let(:emory_low_file_set_attributes) do
    { "id" => emory_low_file_set_id,
      "has_model_ssim" => "FileSet",
      "visibility_ssi" => "emory_low",
      "read_access_group_ssim" => ["emory_low"] }
  end
  let(:restricted_file_set_attributes) do
    { "id" => restricted_file_set_id,
      "has_model_ssim" => "FileSet",
      "visibility_ssi" => "private",
      "read_access_group_ssim" => ["private"] }
  end
  let(:emory_high_file_set_attributes) do
    { "id" => emory_high_file_set_id,
      "has_model_ssim" => "FileSet",
      "visibility_ssi" => "authenticated",
      "read_access_group_ssim" => ["registered"] }
  end
  let(:rose_high_view_file_set_attributes) do
    { "id" => rose_high_view_file_set_id,
      "has_model_ssim" => "FileSet",
      "visibility_ssi" => "rose_high",
      "read_access_group_ssim" => ["rose_high"] }
  end
  before do
    solr = Blacklight.default_index.connection
    solr.add([public_low_view_file_set_attributes,
              public_file_set_attributes,
              restricted_file_set_attributes,
              emory_low_file_set_attributes,
              emory_high_file_set_attributes,
              rose_high_view_file_set_attributes])
    solr.commit
    allow(Hyrax::DerivativePath).to receive(:derivative_path_for_reference).with(any_args).and_return("#{fixture_path}/balloon.jpeg")
  end

  describe "GET" do
    context "a Public Low View object" do
      context "thumbnail" do
        it "returns a thumbnail for an admin user" do
          login_as admin
          get("/iiif/#{public_low_view_file_set_id}/thumbnail")
          expect(response.status).to eq 200
        end

        it "returns a thumbnail for a not-logged-in user" do
          get("/iiif/#{public_low_view_file_set_id}/thumbnail")
          expect(response.status).to eq 200
          expect(response.body).not_to be_empty
        end
      end
    end

    context "a Public object" do
      context "thumbnail" do
        it "returns a thumbnail for a logged in user" do
          login_as user
          get("/iiif/#{public_file_set_id}/thumbnail")
          expect(response.status).to eq 200
        end

        it "returns a thumbnail for a not-logged-in user" do
          get("/iiif/#{public_file_set_id}/thumbnail")
          expect(response.status).to eq 200
        end
      end
    end

    # A restricted object is a Private object, and only Curate admins can see it
    context "a Private/Restricted object" do
      it "as an admin user, I can download the thumbnail" do
        login_as admin
        get("/iiif/#{restricted_file_set_id}/thumbnail")
        expect(response.status).to eq 200
      end
      it "cannot download the thumbnail as a non-logged-in-user" do
        get("/iiif/#{restricted_file_set_id}/thumbnail")
        expect(response.status).to eq 403
        expect(response.body).to be_empty
      end
    end

    context "an Emory Low Download object" do
      context "thumbnail" do
        it "returns a thumbnail for an admin user" do
          login_as admin
          get("/iiif/#{emory_low_file_set_id}/thumbnail")
          expect(response.status).to eq 200
        end
        it "returns a thumbnail for a user authenticated through Lux" do
          get(
            "/iiif/#{emory_low_file_set_id}/thumbnail",
            headers: { "HTTP_COOKIE" => "#{cookie_name}=#{encrypted_cookie_value}" }
          )
          expect(response.status).to eq 200
        end
        it "does not return a thumbnail for a not-logged-in user" do
          get("/iiif/#{emory_low_file_set_id}/thumbnail")
          expect(response.status).to eq 403
          expect(response.body).to be_empty
        end
      end
    end
    context "an Emory High Download object" do
      context "thumbnail" do
        it "returns a thumbnail for an admin user" do
          login_as admin
          get("/iiif/#{emory_high_file_set_id}/thumbnail")
          expect(response.status).to eq 200
        end
        it "returns a thumbnail for a user authenticated through Lux" do
          get(
            "/iiif/#{emory_high_file_set_id}/thumbnail",
            headers: { "HTTP_COOKIE" => "#{cookie_name}=#{encrypted_cookie_value}" }
          )
          expect(response.status).to eq 200
        end
        it "does not return a thumbnail for a not-logged-in user" do
          get("/iiif/#{emory_high_file_set_id}/thumbnail")
          expect(response.status).to eq 403
          expect(response.body).to be_empty
        end
      end
    end
    context "a Rose High View object" do
      context "thumbnail" do
        context "outside the Rose Reading Room" do
          it "returns a thumbnail for an admin user" do
            login_as admin
            get(
              "/iiif/#{rose_high_view_file_set_id}/thumbnail",
              headers: { "X-Forwarded-For": non_reading_room_ip }
            )
            expect(response.status).to eq 200
          end
          it "does not return a thumbnail for a user authenticated through Lux" do
            get(
              "/iiif/#{rose_high_view_file_set_id}/thumbnail",
              headers: { "HTTP_COOKIE" => "#{cookie_name}=#{encrypted_cookie_value}", "X-Forwarded-For": non_reading_room_ip }
            )
            expect(response.status).to eq 403
            expect(response.body).to be_empty
          end
          it "does not return a thumbnail for a not-logged-in user" do
            get(
              "/iiif/#{rose_high_view_file_set_id}/thumbnail",
              headers: { "X-Forwarded-For": non_reading_room_ip }
            )
            expect(response.status).to eq 403
            expect(response.body).to be_empty
          end
        end
        context "in the Rose Reading Room" do
          it "returns a thumbnail for an admin user" do
            login_as admin
            get("/iiif/#{rose_high_view_file_set_id}/thumbnail")
            expect(response.status).to eq 200
          end
          it "returns a thumbnail for a user authenticated through Lux" do
            get(
              "/iiif/#{rose_high_view_file_set_id}/thumbnail",
              headers: { "HTTP_COOKIE" => "#{cookie_name}=#{encrypted_cookie_value}", "X-Forwarded-For": reading_room_ip }
            )
            expect(response.status).to eq 200
          end
          it "returns a thumbnail for a not-logged-in user" do
            get(
              "/iiif/#{rose_high_view_file_set_id}/thumbnail",
              headers: { "X-Forwarded-For": reading_room_ip }
            )
            expect(response.status).to eq 200
          end
        end
      end
    end
  end
end
