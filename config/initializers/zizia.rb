Zizia.config do |config|
  config.metadata_mapper_class = CurateMapper
  config.default_info_stream = Rails.logger
  config.default_error_stream = Rails.logger
end
