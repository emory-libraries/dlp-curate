# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'
require_relative '../app/logging/log_formatter'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module DlpCurate
  class Application < Rails::Application
    # Deprecation Warning: As of Curate v3, Zizia and this requirement will be removed.
    require 'zizia'

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2
    config.log_formatter = LogFormatter.new
    config.x.curate_template = '-cor'
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    config.active_job.queue_adapter = :sidekiq
    config.autoload_paths += %W[#{config.root}/lib]
    # Change below was necessary to institute Source/Deposit Collection structure.
    # For more information, read the SOURCE_DEPOSIT_CHANGES_README.md in dlp-curate's root folder.
    config.to_prepare do
      Hyrax::Dashboard::CollectionsController.prepend Hyrax::Dashboard::CollectionsControllerOverride
      Hyrax::Admin::CollectionTypesController.prepend Hyrax::Admin::CollectionTypesControllerOverride
    end
  end
end
