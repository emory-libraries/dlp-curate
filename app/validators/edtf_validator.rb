# frozen_string_literal: true

class EdtfValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value == "XXXX"

    if Array(value).any? { |v| EDTF.parse(v).nil? }
      # EDTF.parse returns nil if the string is invalid EDTF
      record.errors.add(attribute, (options[:message] || "Please specify the correct date range"))
    end
  rescue StandardError
    record.errors.add(attribute, "Please specify the correct date range")
  end
end
