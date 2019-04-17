source 'https://rubygems.org'

ruby '>=2.4.2', '<=2.5.99'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

gem 'bootstrap-sass', '~> 3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.2'
gem 'devise'
gem 'devise-guests', '~> 0.6'
gem 'dotenv-rails'
gem 'factory_bot_rails', '~> 4.11.1'
gem 'ffaker'
gem 'hydra-role-management'
gem 'hyrax', '3.0.0-beta1'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
gem 'jquery-rails'
gem 'omniauth-shibboleth', '~> 1.3'
# Use Puma as the app server
gem 'puma', '~> 3.7'
# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.1.6'
gem 'riiif', '~> 2.0'
gem 'rsolr', '>= 1.0'

# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use sqlite3 as the database for Active Record
gem 'sqlite3', '~> 1.3.7'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
gem 'twitter-typeahead-rails', '0.11.1.pre.corejavascript'
# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby
gem 'mysql2'
gem 'sidekiq'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

group :development, :test do
  gem 'bixby' # bixby = rubocop rules for Hyrax apps
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'pry' unless ENV['CI']
  gem 'pry-byebug' unless ENV['CI']
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '~> 2.13'
  gem 'coveralls', require: false
  gem 'database_cleaner'
  gem 'webdrivers', '~> 3.0'
end

group :development do
  gem 'listen', '>= 3.0.5', '< 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console', '>= 3.3.0'
end

group :development do
  gem "capistrano", "~> 3.11", require: false
  gem 'capistrano-bundler', '~> 1.3'
  gem 'capistrano-ext'
  gem 'capistrano-passenger'
  gem 'capistrano-rails'
  gem 'capistrano-rails-collection'
  gem 'capistrano-sidekiq', '~> 0.20.0'
end

group :development, :test do
  gem 'solr_wrapper', '>= 0.3'
end

group :development, :test do
  gem 'fcrepo_wrapper'
  gem 'rspec-its'
  gem 'rspec-rails'
end
