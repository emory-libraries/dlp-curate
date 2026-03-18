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
gem 'bulkrax', '~> 8.2.0'
gem 'clamby', '~> 1.6', require: ENV['HYRAX_CLAMAV'] == 'true'
gem 'coffee-rails', '~> 4.2'
gem 'dartsass-sprockets'
gem 'devise'
gem 'devise-guests', '~> 0.8'
gem 'dotenv-rails'
gem 'edtf-humanize', '~> 1.0.0'

if RUBY_PLATFORM.match?(/musl/)
  # # Disabled due to dependency mismatches in Alpine packages (grpc 1.62.1 needs protobuf ~> 3.25)
  #   path '/usr/lib/ruby/gems/3.3.0' do
  gem 'google-protobuf', force_ruby_platform: true
  gem 'grpc', force_ruby_platform: true
  #   end
end

gem 'honeybadger'
gem 'http'
gem 'hydra-role-management'
gem 'hyrax', '~> 5.2'
gem 'jbuilder', '~> 2.5'
gem 'jquery-rails'
gem 'linkeddata', '>= 3.1.6'
gem 'mysql2'
gem 'omniauth', '~> 1.9'
gem 'omniauth-shibboleth', '~> 1.3'
gem 'pg', require: false
gem 'puma'
gem 'rails', '6.1.7.10'
gem 'riiif', '~> 2.8'
gem 'sidekiq', '~> 7.0'
gem 'sidekiq-limit_fetch'
gem 'stackprof', require: false
gem 'turbolinks', '~> 5'
gem 'twitter-typeahead-rails', '0.11.1.pre.corejavascript'
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby] # Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'uglifier', '>= 1.3.0'
gem 'whenever', require: false

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
  gem 'selenium-webdriver'
  gem 'sqlite3', '~> 1.6'
  gem 'webdrivers'
  gem 'webmock'
  gem 'yard'
end

group :test do
  gem 'rspec_junit_formatter'
  gem 'shoulda-callback-matchers', '~> 1.1.1'
  gem 'show_me_the_cookies' # Has capybara as dependency.
end
