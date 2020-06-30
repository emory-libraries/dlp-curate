# frozen_string_literal: true

RSpec.shared_examples "check_page_for_multiple_text" do |array, verbiage|
  it verbiage do
    array.each do |str|
      expect(page).to have_content(str)
    end
  end
end
