# frozen_string_literal: true
# This form comes from escowles via laevigata.
# https://github.com/curationexperts/laevigata/commit/14815b9703bea4a46462904e46c6066d52f77720
# https://github.com/curationexperts/laevigata/blob/master/app/forms/single_valued_form.rb
module SingleValuedForm
  extend ActiveSupport::Concern
  included do
    class_attribute :single_valued_fields
    self.single_valued_fields = []

    def multiple?(field)
      if single_valued_fields.include?(field.to_sym)
        false
      else
        super
      end
    end

    def [](key)
      return Array(super).first if single_valued_fields.include?(key.to_sym)
      super
    end

    def initialize_field(key)
      return if single_valued_fields.include?(key.to_sym)
      return if [:preservation_workflow].include?(key.to_sym)
      super
    end
  end

  class_methods do
    def multiple?(field)
      if single_valued_fields.include?(field.to_sym)
        false
      else
        super
      end
    end

    def model_attributes(form_params)
      super.tap do |params|
        single_valued_fields.each do |field|
          next if !params.key?(field) && !params.key?(field.to_s)
          params[field.to_s] = Array.wrap(params[field.to_s])
        end
      end
    end
  end
end
