# frozen_string_literal: true
module Hyrax
  module Renderers
    class FormatRenderer < AttributeRenderer
      private

        def attribute_value_to_html(value)
          FormatLabelService.instance.label(uri: value)
        end
    end
  end
end
