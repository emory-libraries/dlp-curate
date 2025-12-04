# frozen_string_literal: true

source 'https://rubygems.org'

ruby '~> 3.2.2'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

gem 'archivesspace-client'
gem 'blacklight_iiif_search'
gem 'bootsnap', '>= 1.1.0', require: false
gem 'bootstrap', '~> 4.0'
gem 'bootstrap-sass', '~> 3.0'
gem 'bulkrax', '~> 8.2.0'
gem 'clamby'
gem 'coffee-rails', '~> 4.2'
gem 'devise'
gem 'devise-guests', '~> 0.8'
gem 'dotenv-rails'
gem 'edtf-humanize', '~> 1.0.0'
gem 'honeybadger'
gem 'http'
gem 'hydra-role-management'
gem 'hyrax', '~> 5.2'
gem 'linkeddata', '>= 3.1.6'
gem 'mysql2'
gem 'omniauth', '~> 1.9'
gem 'omniauth-shibboleth', '~> 1.3'
gem 'puma'
gem 'rails', '~> 6.1'
gem 'riiif', '~> 2.1'
gem 'sidekiq', '~> 7.0'
gem 'sidekiq-limit_fetch'
gem 'stackprof', require: false
gem 'turbolinks', '~> 5'
gem 'twitter-typeahead-rails', '0.11.1.pre.corejavascript'
gem 'tzinfo-data', platforms: [:windows, :jruby] # Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'uglifier', '>= 1.3.0'
gem 'webpacker', '~> 5.x'
gem 'whenever', require: false
# Deprecation Warning: As of Curate v3, Zizia will be removed.
# gem 'zizia', '~> 5.5.0'

group :development do
  gem 'bcrypt_pbkdf'
  gem "capistrano", require: false
  gem 'capistrano-bundler', '~> 1.3', require: false
  gem 'capistrano-ext'
  gem 'capistrano-passenger'
  gem 'capistrano-rails', "~> 1.6", require: false
  gem 'capistrano-rails-collection'
  gem 'ec2_ipv4_retriever', git: 'https://github.com/emory-libraries/ec2_ipv4_retriever', branch: 'main'
  gem 'ed25519', '>= 1.2', '< 2.0'
  gem 'fcrepo_wrapper'
  gem 'solr_wrapper', '>= 0.3'
  gem 'web-console', '>= 3.3.0'
  gem 'xray-rails', git: "https://github.com/brentd/xray-rails", branch: "bugs/ruby-3.0.0"
end

group :development, :test do
  gem 'bixby'
  gem 'coveralls', require: false
  gem 'factory_bot_rails'
  gem 'ffaker'
  gem 'pry' unless ENV['CI']
  gem 'pry-byebug' unless ENV['CI']
  gem 'rails-controller-testing'
  gem 'rspec-its'
  gem 'rspec-rails'
  gem 'selenium-webdriver', '~> 4.4'
  gem 'sqlite3', '~> 1.3.7'
  gem 'webdrivers'
  gem 'webmock'
  gem 'yard'
end

group :test do
  gem 'rspec_junit_formatter'
  gem 'shoulda-callback-matchers', '~> 1.1.1'
  gem 'show_me_the_cookies' # Has capybara as dependency.
end
