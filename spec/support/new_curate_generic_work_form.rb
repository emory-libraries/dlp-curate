# frozen_string_literal: true
class NewCurateGenericWorkForm
  include Capybara::DSL

  def visit_new_page
    visit('/concern/curate_generic_works/new')

    self
  end

  def metadata_fill_in_with
    fill_in "curate_generic_work[title]", with: "Example title"
    fill_in "curate_generic_work[holding_repository]", with: "Woodruff"
    fill_in "curate_generic_work[date_created]", with: Date.new(2018, 1, 12)
    select("Audio", from: "Content type")
    select("In Copyright", from: "Rights statement")
    fill_in "curate_generic_work[rights_statement_controlled]", with: "Controlled Rights Statement"
    select("Public", from: "Data classification")

    self
  end

  def attach_files
    within('span#addfiles') do
      attach_file("files[]", "#{Hyrax::Engine.root}/spec/fixtures/image.jp2", visible: false)
      attach_file("files[]", "#{Hyrax::Engine.root}/spec/fixtures/jp2_fits.xml", visible: false)
    end

    self
  end

  def check_visibility
    find('body').click
    choose('curate_generic_work_visibility_open')

    self
  end
end
