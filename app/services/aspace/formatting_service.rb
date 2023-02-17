# frozen_string_literal: true

module Aspace
  class FormattingService
    def initialize; end

    def format_repository; end

    def format_resource; end

    def format_primary_language(lang)
      data = JSON.parse(File.read(Rails.root.join("app", "standards", "iso639_2.json")))
      data.fetch(lang, '')
    end
  end
end
