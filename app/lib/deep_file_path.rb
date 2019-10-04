# frozen_string_literal: true

class DeepFilePath
  attr_accessor :full_path

  def initialize(beginning:, ending:)
    @full_path = Dir.glob([beginning, '/**/', ending].join).first
  end

  delegate :to_s, to: :full_path
end
