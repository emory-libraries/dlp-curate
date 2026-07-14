# frozen_string_literal: true

class ValidationsController < ApplicationController
  def edtf
    value = params[:value]

    # Returns true if parsed successfully, false otherwise
    is_valid = begin
           Array(value).all? { |v| EDTF.parse(v).present? } || value == 'XXXX'
               rescue
                 return false
         end

    render json: { valid: is_valid }
  end
end
