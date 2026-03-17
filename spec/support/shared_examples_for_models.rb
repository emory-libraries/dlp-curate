# frozen_string_literal: true

RSpec.shared_examples 'checks model for new attribute response' do |attribute_text|
  describe "##{attribute_text}" do
    it { is_expected.to respond_to(attribute_text.to_sym) }
  end
end
