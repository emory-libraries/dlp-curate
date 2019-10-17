# frozen_string_literal: true
# [Hyrax-overwrite] Adds test for preservation_event on work creation
require 'rails_helper'

RSpec.describe CreateWorkJob do
  let(:user) { FactoryBot.create(:user) }
  let(:log) do
    Hyrax::Operation.create!(user: user,
                             operation_type: "Create Work")
  end

  describe "#perform", perform_enqueued: [described_class] do
    subject :cgw do
      described_class.perform_later(user,
                                    'CurateGenericWork',
                                    metadata,
                                    log)
    end
    let(:file1) { File.open(fixture_path + '/world.png') }
    let(:upload1) { Hyrax::UploadedFile.create(user: user, file: file1) }
    let(:metadata) do
      { keyword: [],
        "permissions_attributes" => [{ "type" => "group", "name" => "public", "access" => "read" }],
        "visibility" => 'open',
        uploaded_files: [upload1.id],
        title: ['File One'],
        resource_type: ['Article'] }
    end
    let(:work) { FactoryBot.create(:public_generic_work) }
    let(:actor) { instance_double(Hyrax::Actors::CurateGenericWorkActor) }

    before do
      allow(Hyrax::CurationConcern).to receive(:actor).and_return(actor)
      allow(CurateGenericWork).to receive(:new).and_return(work)
    end

    context "when the update is successful" do
      it "logs the success and preservation_event" do
        expect(actor).to receive(:create).with(Hyrax::Actors::Environment) do |env|
          expect(env.attributes).to eq("keyword" => [],
                                       "title" => ['File One'],
                                       "resource_type" => ["Article"],
                                       "permissions_attributes" =>
                                                 [{ "type" => "group", "name" => "public", "access" => "read" }],
                                       "visibility" => "open",
                                       "uploaded_files" => [upload1.id])
        end.and_return(true)
        cgw
        expect(log.reload.status).to eq 'success'
        expect(work.preservation_event.first.event_type).to eq ['Object Validation (Work created)']
        expect(work.preservation_event.first.outcome).to eq ['Success']
        expect(work.preservation_event.first.initiating_user).to eq [user.uid]
        expect(work.preservation_event.count).to eq 1
      end
    end

    context "when the actor does not create the work" do
      it "logs the failure" do
        expect(actor).to receive(:create).and_return(false)
        cgw
        expect(log.reload.status).to eq 'failure'
      end
    end
  end
end
