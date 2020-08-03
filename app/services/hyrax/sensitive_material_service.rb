# frozen_string_literal: true

module Hyrax
  class SensitiveMaterialService < QaSelectService
    def initialize
      super('sensitive_material')
    end

    def select_active_options
      active_elements.map do |e|
        label = e[:id] == true ? "Yes" : "No"
        [label, e[:id]]
      end
    end
  end
end
