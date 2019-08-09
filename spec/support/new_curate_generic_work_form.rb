# frozen_string_literal: true
require 'rails_helper'
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
    select("Audio", from: "Format")
    select("In Copyright", from: "Rights Statement")
    fill_in "curate_generic_work[rights_statement_text][]", with: "Controlled Rights Statement"
    select("Public", from: "Data Classification")

    self
  end

  def attach_files
    click_link "Files"
    fill_in "fsn0", with: "Example fileset"
    attach_file("pmf0", "#{::Rails.root}/spec/fixtures/image.jp2", visible: false)
    attach_file("sf0", "#{::Rails.root}/spec/fixtures/sun.png", visible: false)
    attach_file("imf0", "#{::Rails.root}/spec/fixtures/world.png", visible: false)
    attach_file("et0", "#{::Rails.root}/spec/fixtures/image.jp2", visible: false)
    attach_file("ts0", "#{::Rails.root}/spec/fixtures/world.png", visible: false)
    find('#fs_use0').find(:xpath, 'option[1]').select_option

    self
  end

  def check_visibility
    find('body').click
    choose('curate_generic_work_visibility_open')

    self
  end
end
