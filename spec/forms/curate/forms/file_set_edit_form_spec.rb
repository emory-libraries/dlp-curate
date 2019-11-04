# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Curate::Forms::FileSetEditForm do
  subject(:file_set) { described_class.new(FileSet.new) }

  describe '#terms' do
    it 'returns a list' do
      expect(file_set.terms).to eq(
        [:resource_type, :title, :creator, :contributor, :description, :keyword,
         :license, :publisher, :date_created, :subject, :language, :identifier,
         :based_near, :related_url,
         :visibility_during_embargo, :visibility_after_embargo, :embargo_release_date,
         :visibility_during_lease, :visibility_after_lease, :lease_expiration_date,
         :visibility, :pcdm_use]
      )
    end

    it "doesn't contain fields that users shouldn't be allowed to edit" do
      # date_uploaded is reserved for the original creation date of the record.
      expect(file_set.terms).not_to include(:date_uploaded)
    end
  end

  it 'initializes multivalued fields' do
    expect(file_set.title).to eq ['']
  end

  describe '.model_attributes' do
    let(:params) do
      ActionController::Parameters.new(
        title: ['foo'],
        "visibility" => "on-campus",
        "visibility_during_embargo" => "restricted",
        "embargo_release_date" => "2015-10-21",
        "visibility_after_embargo" => "open",
        "visibility_during_lease" => "open",
        "lease_expiration_date" => "2015-10-21",
        "visibility_after_lease" => "restricted",
        "pcdm_use" => "Primary Content"
      )
    end

    let(:file_set) { described_class.model_attributes(params) }

    it 'changes only the title' do
      expect(file_set['title']).to eq ['foo']
      expect(file_set['visibility']).to eq('on-campus')
      expect(file_set['visibility_during_embargo']).to eq('restricted')
      expect(file_set['visibility_after_embargo']).to eq('open')
      expect(file_set['embargo_release_date']).to eq('2015-10-21')
      expect(file_set['visibility_during_lease']).to eq('open')
      expect(file_set['visibility_after_lease']).to eq('restricted')
      expect(file_set['lease_expiration_date']).to eq('2015-10-21')
      expect(file_set['pcdm_use']).to eq('Primary Content')
    end
  end
end
