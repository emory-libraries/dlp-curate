# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Hyrax::CurateGenericWorkForm do
  describe '::terms' do
    subject { described_class }
    its(:terms) { is_expected.to include(:title) }
    its(:terms) { is_expected.to include(:creator) }
    its(:terms) { is_expected.to include(:rights_statement) }
    its(:terms) { is_expected.to include(:conference_name) }
    its(:terms) { is_expected.to include(:institution) }
    its(:terms) { is_expected.to include(:volume) }
    its(:terms) { is_expected.to include(:sublocation) }
    its(:terms) { is_expected.to include(:subject_names) }
    its(:terms) { is_expected.to include(:internal_rights_note) }
    its(:terms) { is_expected.to include(:issue) }
  end

  describe 'form fields' do
    let(:params) do
      {
        'title':       ['This Title'],
        'creator':     ['Me'],
        'keywords':    ['Test', 'Thing'],
        'institution': ['Emory University', 'CDC']
      }
    end

    it 'repeats some fields' do
      allow(Hyrax::Forms::WorkForm).to receive(:sanitize_params).with(params)
      described_class.sanitize_params(params)
      expect(params[:keywords]).to eq ['Test', 'Thing']
      expect(params[:institution]).to eq ['Emory University', 'CDC']
    end

    it 'does not repeat some fields' do
      allow(Hyrax::Forms::WorkForm).to receive(:sanitize_params).with(params)
      described_class.sanitize_params(params)
      expect(params[:title]).to eq ['This Title']
      expect(params[:creator]).to eq ['Me']
    end
  end
end
