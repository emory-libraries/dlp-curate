# frozen_string_literal: true

module Aspace
  class FormattingService
    def initialize; end

    def format_repository(data)
      data[:administrative_unit] = format_administrative_unit(data[:repository_id])
      data[:holding_repository] = format_holding_repository(data[:repository_id])
      data
    end

    def format_resource(data)
      data[:primary_language] = format_primary_language(data[:primary_language])
      data[:system_of_record_id] = 'aspace:' + data[:uri]
      data[:finding_aid_link] = ENV['ARCHIVES_SPACE_PUBLIC_BASE_URL'].chomp('/') + data[:uri]
      data
    end

    def format_primary_language(s)
      map = JSON.parse(File.read(Rails.root.join("app", "standards", "iso639_2.json")))
      map.fetch(s, '')
    end

    def format_holding_repository(id)
      map = {
        '2' => "Pitts Theology Library",
        '3' => "Stuart A. Rose Manuscript, Archives, and Rare Book Library",
        '4' => "MacMillan Law Library",
        '5' => "Robert W. Woodruff Health Sciences Center. Library",
        '6' => "Oxford College Library (Oxford, Ga.)",
        '7' => "Stuart A. Rose Manuscript, Archives, and Rare Book Library"
      }
      map.fetch(id, '')
    end

    def format_administrative_unit(id)
      map = {
        '3' => "Emory University Archives",
        '7' => "Stuart A. Rose Manuscript, Archives, and Rare Book Library"
      }
      map.fetch(id, '')
    end
  end
end
