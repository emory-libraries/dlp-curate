# frozen_string_literal: true

# Deprecation Warning: As of Curate v3, Zizia and this initializer will be removed.
Zizia.config do |config|
  config.metadata_mapper_class = CurateMapper
end
