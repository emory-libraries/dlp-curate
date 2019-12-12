# frozen_string_literal: true

module Hyrax
  class PublisherVersionService < QaSelectService
    def initialize
      super('publisher_version')
    end
  end
end
