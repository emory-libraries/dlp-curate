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

  describe ".build_permitted_params" do
    subject { described_class.build_permitted_params }

    context "without mediated deposit" do
      it {
        is_expected.to include(:representative_id,
                               :thumbnail_id,
                               :admin_set_id,
                               :visibility_during_embargo,
                               :embargo_release_date,
                               :visibility_after_embargo,
                               :visibility_during_lease,
                               :lease_expiration_date,
                               :visibility_after_lease,
                               :visibility,
                               ordered_member_ids: [])
      }
    end
  end

  describe ".model_attributes" do
    subject :permitted_params do
      described_class.model_attributes(params)
    end

    let(:params) { ActionController::Parameters.new(attributes) }
    let(:attributes) do
      { visibility:         'open',
        representative_id:  '456',
        thumbnail_id:       '789',
        rights_statement:   'http://rightsstatements.org/vocab/InC-EDU/1.0/',
        ordered_member_ids: ['123', '456'] }
    end

    it 'permits parameters' do
      expect(permitted_params['visibility']).to eq 'open'
      expect(permitted_params['rights_statement']).to eq 'http://rightsstatements.org/vocab/InC-EDU/1.0/'
      expect(permitted_params['ordered_member_ids']).to eq ['123', '456']
    end
  end
end
