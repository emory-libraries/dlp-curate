# frozen_string_literal: true
require 'connection_pool'

size = ENV.fetch("HYRAX_REDIS_POOL_SIZE", 5)
timeout = ENV.fetch("HYRAX_REDIS_TIMEOUT", 5)

Hyrax.config.redis_connection =
  ConnectionPool::Wrapper.new(size:, timeout:) { Redis.new(Rails.application.config_for(:redis)) }
