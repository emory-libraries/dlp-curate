# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Hyrax::CurateGenericWorksController, :clean do
  let(:work) { FactoryBot.create(:public_generic_work, id: '888889', user:) }
  let(:user) { FactoryBot.create(:user) }
  let(:admin) { FactoryBot.create(:admin) }

  describe "GET #manifest" do
    before { ENV['IIIF_MANIFEST_CACHE'] = "./tmp" }

    it "returns http success" do
      sign_in user
      get :manifest, params: { id: work.id, format: 'json' }
      expect(response).to have_http_status(:success)
    end
  end

  describe "#permissions_changed?" do
    subject(:permissions_changed) { controller.send(:permissions_changed?) }

    context "with a Valkyrie work" do
      let(:resource) { CurateGenericWorkResource.new(id: 'valkyrie-work') }
      let(:admin_edit) { Hyrax::Permission.new(access_to: resource.id, agent: 'group/admin', mode: :edit) }
      let(:depositor_edit) { Hyrax::Permission.new(access_to: resource.id, agent: 'dev-admin', mode: :edit) }
      let(:public_read) { Hyrax::Permission.new(access_to: resource.id, agent: 'group/public', mode: :read) }

      before do
        controller.curation_concern = resource
        controller.instance_variable_set(:@saved_permissions, [admin_edit, depositor_edit, public_read])
        allow(Hyrax::AccessControl).to receive(:for).with(resource:)
                                                    .and_return(instance_double(Hyrax::AccessControl, permissions: current_permissions))
      end

      context "when the saved permissions come back in a different order" do
        let(:current_permissions) { [public_read, depositor_edit, admin_edit] }

        it { is_expected.to be false }
      end

      context "when a permission was removed" do
        let(:current_permissions) { [admin_edit, depositor_edit] }

        it { is_expected.to be true }
      end

      context "when a permission was added" do
        let(:current_permissions) do
          [admin_edit, depositor_edit, public_read, Hyrax::Permission.new(access_to: resource.id, agent: 'group/registered', mode: :read)]
        end

        it { is_expected.to be true }
      end
    end

    context "with an AF work" do
      before do
        controller.curation_concern = work
        controller.instance_variable_set(:@saved_permissions, work.permissions.map(&:to_hash))
      end

      it "is false when the permissions are unchanged" do
        expect(permissions_changed).to be false
      end

      it "is true when a permission was added" do
        work.read_groups += ['registered']

        expect(permissions_changed).to be true
      end
    end
  end

  describe "#delete" do
    context "when logged in as an admin" do
      it "redirects to My Works" do
        sign_in admin
        delete :destroy, params: { id: work }
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(Hyrax::Engine.routes.url_helpers.my_works_path(locale: 'en'))
        expect(flash[:notice]).to eq "Deleted Test title"
        expect(CurateGenericWork.count).to eq 0
      end
    end

    context "when logged in as a non-admin user" do
      it "redirects to the edit view" do
        sign_in user
        delete :destroy, params: { id: work }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to render_template(:edit)
        expect(flash[:notice]).to eq "Test title could not be deleted"
        expect(CurateGenericWork.count).to eq 1
      end
    end
  end
end
