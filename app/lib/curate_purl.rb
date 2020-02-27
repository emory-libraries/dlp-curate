# frozen_string_literal: true

# This module will be used to define persistent url
# for works and collections
module CuratePurl
  def purl
    "#{ENV['LUX_BASE_URL'] || ''}/purl/#{id}"
  end
end
