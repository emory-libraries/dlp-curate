# frozen_string_literal: true

Redis.current = Redis.new(Rails.application.config_for(:redis))
