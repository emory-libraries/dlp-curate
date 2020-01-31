# frozen_string_literal: true

redis_config = Rails.application.config_for(:redis)
redis_url = "redis://#{redis_config[:host]}:#{redis_config[:port]}/#{redis_config[:db]}"

Sidekiq.configure_server do |config|
  config.redis = { url: redis_url }
end

Sidekiq.configure_client do |config|
  config.redis = { url: redis_url }
end
