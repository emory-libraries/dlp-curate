# frozen_string_literal: true
# Hydra::AccessControls v13.2.0 Override (Bug Fix): only operate if `obj` is present.

Rails.application.config.to_prepare do
  Hydra::AccessControl.class_eval do
    def permissions_attributes=(attribute_list)
      raise ArgumentError unless attribute_list.is_a? Array
      any_destroyed = false
      attribute_list.each do |attributes|
        if attributes.key?(:id)
          obj = relationship.find(attributes[:id])
          if has_destroy_flag?(attributes) && obj.present? # Emory Altered
            obj.destroy
            any_destroyed = true
          elsif obj.present? # Emory Altered
            obj.update(attributes.except(:id, '_destroy'))
          end
        else
          relationship.build(attributes)
        end
      end
      # Poison the cache
      save! && relationship.reset if any_destroyed
    end
  end
end
