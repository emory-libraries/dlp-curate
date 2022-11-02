# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work CurateGenericWork`
require 'rails_helper'

RSpec.describe Hyrax::Actors::CurateGenericWorkActor, :clean do
  let(:env) { Hyrax::Actors::Environment.new(curation_concern, ability, attributes) }
  let(:user) { FactoryBot.create(:user) }
  let(:ability) { ::Ability.new(user) }

  describe "#create" do
    subject(:middleware) do
      stack = ActionDispatch::MiddlewareStack.new.tap do |middleware|
        middleware.use Hyrax::Actors::CreateWithFilesActor
        middleware.use Hyrax::Actors::AddToWorkActor
        middleware.use Hyrax::Actors::InterpretVisibilityActor
        middleware.use described_class
      end
      stack.build(terminator)
    end

    let(:curation_concern) { FactoryBot.create(:generic_work, user: user) }
    let(:attributes) { {} }
    let(:terminator) { Hyrax::Actors::Terminator.new }

    before do
      allow(terminator).to receive(:create).and_return(true)
    end

    context 'success' do
      it "invokes the after_create_concern callback, creates work, and its preservation_events" do
        expect(Hyrax.config.callback).to receive(:run)
          .with(:after_create_concern, curation_concern, user, warn: false)
        middleware.create(env)
        expect(curation_concern.preservation_event.pluck(:event_type)).to include ['Validation']
        expect(curation_concern.preservation_event.first.outcome).to eq ['Success']
        expect(curation_concern.preservation_event.first.initiating_user).to eq [user.uid]
        expect(curation_concern.preservation_event.pluck(:event_details)).to include ['Visibility/access controls assigned: restricted']
        expect(curation_concern.preservation_event.count).to eq 2
      end
    end
  end

  describe '#update' do
    let(:curation_concern) { FactoryBot.create(:generic_work, user: user) }
    let(:work_actor) { Hyrax::CurationConcern.actor }

    context 'success' do
      let(:attributes) { { title: ['Other Title'] } }

      it "invokes the after_update_metadata callback, updates work, creates modification preservation_event" do
        expect(Hyrax.config.callback).to receive(:run)
          .with(:after_update_metadata, curation_concern, user, warn: false)
        work_actor.update(env)
        expect(curation_concern.preservation_event.pluck(:event_type)).to include ['Modification']
      end
    end
  end
end
