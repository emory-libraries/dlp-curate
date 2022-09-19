# frozen_string_literal: true

module CurateFormBehavior
  # Cast back to multi-value when saving
  # Reads from form
  def model_attributes(attributes)
    attrs = super
    return attrs unless attributes[:title]

    attrs[:title] = Array(attributes[:title])
    return attrs if attributes[:alt_title].nil?
    Array(attributes[:alt_title]).each do |value|
      attrs["title"] << value if value != ""
    end
    attrs
  end
end
