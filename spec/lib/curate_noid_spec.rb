# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CurateNoid do
  describe "#mint" do
    subject :mint do
      described_class.new.mint
    end

    it { is_expected.to include '-cor' }
  end
end
