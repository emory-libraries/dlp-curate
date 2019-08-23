require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module DlpCurate
  class Application < Rails::Application
    require 'zizia'

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1
    config.logger = ActiveSupport::Logger.new("log/#{Rails.env}.log")

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    config.active_job.queue_adapter = :sidekiq
  end
end
