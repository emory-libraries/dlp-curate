# frozen_string_literal: true
unless Rails.env.production?
  require 'solr_wrapper/rake_task'

  # Split the test suite into two parts: unit tests and integration tests
  # Integration tests take longer to run individually, but there are fewer
  # of them so the suite as a whole takes less time than unit tests.
  # Bundle integration with style checking and javascript tests (both relatively
  # quick) to create a balanced job

  desc "Run integration CI"
  task :ci do
    with_server 'test' do
      Rake::Task['db:create'].invoke
      Rake::Task['db:migrate'].invoke
      Rake::Task['rubocop'].invoke
      Rake::Task['integration'].invoke
    end
  end
end
