# frozen_string_literal: true

class UrlValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if value.class == String
      record.errors[attribute] << (options[:message] || "is not a valid URL") unless url_valid?(value)
    else
      value.each do |url|
        record.errors[attribute] << (options[:message] || "is not a valid URL") unless url_valid?(url)
      end
    end
  end

  def url_valid?(url)
    begin
      url = URI.parse(url)
    rescue
      false
    end
    url.is_a?(URI::HTTP)
  end
end
