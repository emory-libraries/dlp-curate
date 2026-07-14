# frozen_string_literal: true
require 'rails_helper'
require 'rake'
Rails.application.load_tasks

RSpec.describe 'rake db:seed', :clean do
  it 'adds roles to the Role class' do
    expect(Role.all.count).to be < 15
    Rake::Task['db:seed'].invoke
    expect(Role.all.count).to eq(15)
  end
end
