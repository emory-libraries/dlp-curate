# frozen_string_literal: true

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
