# frozen_string_literal: true
# [Hyrax-overwrite-v3.0.0.pre.rc1] Changes expectations to include initiating user argument
require 'rails_helper'

RSpec.describe Hyrax::Actors::CreateWithFilesActor, :clean do
  let(:user) { FactoryBot.create(:user) }
  let(:ability) { ::Ability.new(user) }
  let(:work) { FactoryBot.create(:generic_work, user: user) }
  let(:env) { Hyrax::Actors::Environment.new(work, ability, attributes) }
  let(:terminator) { Hyrax::Actors::Terminator.new }
  let(:uploaded_file1) { FactoryBot.create(:uploaded_file, user: user) }
  let(:uploaded_file2) { FactoryBot.create(:uploaded_file, user: user) }
  let(:uploaded_file_ids) { [uploaded_file1.id, uploaded_file2.id] }
  let(:attributes) { { uploaded_files: uploaded_file_ids } }

  subject(:middleware) do
    stack = ActionDispatch::MiddlewareStack.new.tap do |middleware|
      middleware.use described_class
    end
    stack.build(terminator)
  end

  [:create, :update].each do |mode|
    context "on #{mode}" do
      before do
        allow(terminator).to receive(mode).and_return(true)
      end
      context "when uploaded_file_ids include nil" do
        let(:uploaded_file_ids) { [nil, uploaded_file1.id, nil] }

        it "will discard those nil values when attempting to find the associated UploadedFile" do
          expect(AttachFilesToWorkJob).to receive(:perform_later)
          expect(Hyrax::UploadedFile).to receive(:find).with([uploaded_file1.id]).and_return([uploaded_file1])
          middleware.public_send(mode, env)
        end
      end

      context "when uploaded_file_ids belong to me" do
        it "attaches files" do
          expect(AttachFilesToWorkJob).to receive(:perform_later).with(CurateGenericWork, [uploaded_file1, uploaded_file2], user, {})
          expect(middleware.public_send(mode, env)).to be true
        end
      end

      context "when uploaded_file_ids don't belong to me" do
        let(:uploaded_file2) { FactoryBot.create(:uploaded_file) }

        it "doesn't attach files" do
          expect(AttachFilesToWorkJob).not_to receive(:perform_later)
          expect(middleware.public_send(mode, env)).to be false
        end
      end

      context "when no uploaded_file" do
        let(:attributes) { {} }

        it "doesn't invoke job" do
          expect(AttachFilesToWorkJob).not_to receive(:perform_later)
          expect(middleware.public_send(mode, env)).to be true
        end
      end
    end
  end
end
