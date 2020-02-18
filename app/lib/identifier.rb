# frozen_string_literal: true

module Identifier
  def assign_id
    CurateNoid.new.mint
  end
end
