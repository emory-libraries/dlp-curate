# frozen_string_literal: true

class GenericWorkResourceForm < Hyrax::Forms::PcdmObjectForm(GenericWorkResource)
  include Hyrax::FormFields(:emory_basic_metadata)
  include Hyrax::FormFields(:generic_work_resource)
end
