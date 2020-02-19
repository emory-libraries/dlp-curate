# frozen_string_literal: true

module CurateIdentifier
  def assign_id
    CurateNoid.new.mint
  end
end
