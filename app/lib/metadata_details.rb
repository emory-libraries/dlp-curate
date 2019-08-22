# frozen_string_literal: true
require 'csv'

class MetadataDetails
  include Singleton

  def details(work_attributes:)
    validators = work_attributes.validators
    work_attributes.properties.sort.map do |p|
      Hash[
        p[0],
        attribute: p[0],
        predicate: p[1].predicate.to_s,
        multiple: p[1].try(:multiple?).to_s,
        type: type_to_s(p[1].type),
        validator: validator_to_string(validator: validators[p[0].to_sym][0]),
        label: I18n.t("simple_form.labels.defaults.#{p[0]}")
                                          ]
    end.reduce({}, :merge)
  end

  def to_csv(work_attributes:)
    details_hash = details(work_attributes: work_attributes)
    headers = [:attribute, :predicate, :multiple, :type, :validator, :label]
    csv_string = CSV.generate do |csv|
      csv << headers
      details_hash.each do |detail|
        csv << headers.map { |h| detail[1][h] }
      end
    end
    csv_string
  end

  private

    def type_to_s(type)
      return 'Not specified' unless type.present?
      type.to_s
    end

    def validator_to_string(validator:)
      case validator
      when ActiveModel::Validations::PresenceValidator
        'required'
      when UrlValidator
        'Must be a URL'
      else
        'No validation present in the model.'
      end
    end
end
