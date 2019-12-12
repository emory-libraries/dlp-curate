# frozen_string_literal: true

module Hyrax
  class SensitiveMaterialService < QaSelectService
    def initialize
      super('sensitive_material')
    end
  end
end
