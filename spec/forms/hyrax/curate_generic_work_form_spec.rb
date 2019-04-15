# Generated via
#  `rails generate hyrax:work CurateGenericWork`
require 'rails_helper'

RSpec.describe Hyrax::CurateGenericWorkForm do
  describe "::terms" do
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
end
