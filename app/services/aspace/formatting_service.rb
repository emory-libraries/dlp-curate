# frozen_string_literal: true

module Aspace
  class FormattingService
    def initialize; end

    def format_repository(h)
      h[:administrative_unit] = format_administrative_unit(h[:administrative_unit])
      h[:holding_repository] = format_holding_repository(h[:holding_repository])
    end

    def format_resource(h)
      h[:primary_language] = format_primary_language(h[:primary_language])
    end

    def format_primary_language(s)
      map = JSON.parse(File.read(Rails.root.join("app", "standards", "iso639_2.json")))
      map.fetch(s, '')
    end

    def format_holding_repository(s)
      map = {
        "Pitts Special Collections and Archives" => "Pitts Theology Library",
        "Emory University Archives" => "Emory University. General Libraries",
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
