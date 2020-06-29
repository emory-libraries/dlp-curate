# frozen_string_literal: true

RSpec.shared_examples 'check_basis_reviewer_for_text' do |type, text|
  it "checks #{type}'s basis_reviewer field for right text" do
    expect(generic_work.preservation_workflow.find { |w| w.workflow_type == [type] }.workflow_rights_basis_reviewer).to eq [text]
  end
end
