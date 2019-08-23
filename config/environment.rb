# Load the Rails application.
require_relative 'application'

# Initialize the Rails application.
Rails.application.initialize!
Rails.logger.datetime_format = "%Y-%m-%d %H:%M:%S"
Rails.logger.level = Logger::INFO
