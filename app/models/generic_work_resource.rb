# frozen_string_literal: true

class GenericWorkResource < Hyrax::Work
  include Hyrax::Schema(:emory_basic_metadata)
  include Hyrax::Schema(:generic_work_resource)
end
