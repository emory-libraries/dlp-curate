# frozen_string_literal: true

class ValidationsController < ApplicationController
  def edtf
    # Returns true if parsed successfully, false otherwise
    is_valid = begin
           Array(params[:value]).all? { |v| EDTF.parse(v).present? }
               rescue
                 return false
         end

    render json: { valid: is_valid }
  end
end
