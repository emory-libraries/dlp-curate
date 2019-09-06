# frozen_string_literal: true
module Hyrax
  module Renderers
    class RightsStatementRenderer < AttributeRenderer
      private

        def attribute_value_to_html(value)
          RightsStatementLabelService.instance.label(uri: value)
        end
    end
  end
end
