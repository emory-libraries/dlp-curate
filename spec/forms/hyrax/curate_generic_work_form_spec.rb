# Generated via
#  `rails generate hyrax:work CurateGenericWork`
require 'rails_helper'

RSpec.describe Hyrax::CurateGenericWorkForm do
  describe "::terms" do
    subject { described_class }
    its(:terms) { is_expected.to include(:publisher) }
    its(:terms) { is_expected.to include(:date_created) }
  end
end
