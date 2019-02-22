
# frozen_string_literal: true
unless Rails.env.production?
  require 'rubocop/rake_task'

  desc 'Run style checker'
  RuboCop::RakeTask.new(:rubocop) do |task|
    task.requires << 'rubocop-rspec'
    task.fail_on_error = true
  end
end
