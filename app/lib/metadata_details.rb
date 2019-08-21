# frozen_string_literal: true
class MetadataDetails
  include Singleton

  def details(work_attributes:)
    validators = work_attributes.validators
    work_attributes.properties.sort.map do |p|
      Hash[
                                            p[0],
                                            predicate: p[1].predicate.to_s,
                                            multiple: p[1].try(:multiple?).to_s,
                                            type: type_to_s(p[1].type),
                                            validator: validator_to_string(validator: validators[p[0].to_sym][0]),
                                            label: I18n.t("simple_form.labels.defaults.#{p[0]}")
                                          ]
    end.reduce({}, :merge)
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
