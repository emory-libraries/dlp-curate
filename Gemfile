# frozen_string_literal: true

source 'https://rubygems.org'

ruby '2.7.4'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

gem 'bootsnap', require: false
gem 'bootstrap-sass', '~> 3.0'
gem 'bulkrax'
gem 'clamby'
gem 'coffee-rails', '~> 4.2'
gem 'devise'
gem 'devise-guests', '~> 0.6'
gem 'dotenv-rails'
gem 'dry-monads', '~> 1.4.0'
gem 'edtf', '~> 3.0.0'
gem 'edtf-humanize', '~> 1.0.0'
gem 'honeybadger', '~> 4.0'
gem 'http'
gem 'hydra-role-management'
gem 'hyrax', '3.4.2'
gem 'jbuilder', '~> 2.5'
gem 'jquery-rails'
gem 'mysql2', '~> 0.5'
gem 'noid-rails'
gem 'omniauth-shibboleth', '~> 1.3'
gem 'puma', '~> 4.3'
gem 'rails', '~> 5.1'
gem 'rdf-vocab', '<= 3.1.4'
gem 'riiif', '~> 2.0'
gem 'rsolr', '>= 1.0'
gem 'sass-rails', '~> 5.0'
gem 'sidekiq'
gem 'sidekiq-limit_fetch'
gem 'stackprof'
gem 'turbolinks', '~> 5'
gem 'twitter-typeahead-rails', '0.11.1.pre.corejavascript'
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby] # Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'uglifier', '>= 1.3.0'
gem 'webpacker', '~> 4.x'
gem 'whenever', require: false
gem 'zizia', '~> 5.5.0'

group :development do
  gem 'cap-ec2-emory', github: 'emory-libraries/cap-ec2'
  gem "capistrano", "~> 3.11", require: false
  gem 'capistrano-bundler', '~> 1.3'
  gem 'capistrano-ext'
  gem 'capistrano-passenger'
  gem 'capistrano-rails'
  gem 'capistrano-rails-collection'
  gem 'fcrepo_wrapper'
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'rubocop-rspec'
  gem 'solr_wrapper', '>= 0.3'
  gem 'web-console', '>= 3.3.0'
  gem 'xray-rails'
end

group :development, :test do
  gem 'bixby', "~> 3.0.1"
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw] unless ENV['CI'] # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'coveralls', require: false
  gem 'factory_bot_rails', '~> 4.11.1'
  gem 'ffaker'
  gem 'pry' unless ENV['CI']
  gem 'pry-byebug' unless ENV['CI']
  gem 'rails-controller-testing'
  gem 'rspec-its'
  gem 'rspec-rails'
  gem 'selenium-webdriver'
  gem 'sqlite3', '~> 1.3.7'
  gem 'webdrivers', '~> 3.0'
  gem 'webmock'
  gem 'yard'
end

group :test do
  gem 'capybara'
  gem 'rspec_junit_formatter'
  gem 'shoulda-callback-matchers', '~> 1.1.1'
  gem 'show_me_the_cookies'
end
