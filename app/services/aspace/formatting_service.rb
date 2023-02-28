# frozen_string_literal: true

module Aspace
  class FormattingService
    def initialize; end

    def format_repository(data)
      data[:administrative_unit] = format_administrative_unit(data[:administrative_unit])
      data[:holding_repository] = format_holding_repository(data[:holding_repository])
      data
    end

    def format_resource(data)
      data[:primary_language] = format_primary_language(data[:primary_language])
      data
    end

    def format_primary_language(s)
      map = JSON.parse(File.read(Rails.root.join("app", "standards", "iso639_2.json")))
      map.fetch(s, '')
    end

    def format_holding_repository(s)
      map = {
        "Pitts Special Collections and Archives" => "Pitts Theology Library",
        "Emory University Archives" => "Stuart A. Rose Manuscript, Archives, and Rare Book Library",
        "Emory Law Archives" => "MacMillan Law Library",
        "Woodruff Health Sciences Library Historical Collections" => "Robert W. Woodruff Health Sciences Center. Library",
        "Oxford College Archives" => "Oxford College Library (Oxford, Ga.)",
        "Stuart A. Rose Manuscript, Archives, and Rare Book Library" => "Stuart A. Rose Manuscript, Archives, and Rare Book Library"
      }
      map.fetch(s, '')
    end

    def format_administrative_unit(s)
      map = {
        "Emory University Archives" => "Emory University Archives",
        "Stuart A. Rose Manuscript, Archives, and Rare Book Library" => "Stuart A. Rose Manuscript, Archives, and Rare Book Library"
      }
      map.fetch(s, '')
    end
  end
end
