# frozen_string_literal: true

# Deprecation Warning: As of Curate v3, Zizia will be removed. This is an artifact
#   of the Zizia install that will likely be removed.
module Zizia
  class WarningAppender
    attr_accessor :row, :warnings

    def initialize(row:, warnings:)
      @row = row
      @warnings = warnings
    end

    def warning; end

    def condition; end
  end
end
