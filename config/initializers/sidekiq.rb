# frozen_string_literal: true

Sidekiq.configure_server do |config|
  config.redis = { url: "redis://#{ENV['REDIS_HOST'] || 'localhost'}:#{ENV['REDIS_PORT'] || 6379}/0" }
end
  
Sidekiq.configure_client do |config|
  config.redis = { url: "redis://#{ENV['REDIS_HOST'] || 'localhost'}:#{ENV['REDIS_PORT'] || 6379}/0" }
end