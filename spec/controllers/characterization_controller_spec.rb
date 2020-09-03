# frozen_string_literal: true
require 'rails_helper'

RSpec.describe CharacterizationController, type: :controller, clean: true do
  let(:user) { FactoryBot.create(:user) }
  let(:file_set) { FactoryBot.create(:file_set, user: user) }

  context 'when signed in' do
    describe 'POST re_characterize' do
      before do
        sign_in user
      end

      it 'queues up characterize job' do
        expect(ReCharacterizeJob).to receive(:perform_later).with(file_set: file_set, user: user.uid)
        post :re_characterize, params: { file_set_id: file_set.id }, xhr: true
        expect(response).to be_success
      end
    end
  end

  context 'when not signed in' do
    describe 'POST re_characterize' do
      it 'returns 401' do
        post :re_characterize, params: { file_set_id: file_set.id }, xhr: true
        expect(response.code).to eq '401'
      end
    end
  end
end
