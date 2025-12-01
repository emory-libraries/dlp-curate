# frozen_string_literal: true

# [Hyrax-overwrite-hyrax-v5.2.0] Note: this version no longer delegates :human_readable_type
#   to :model and considers :license a `required_fields`.
module Curate::Forms
  class FileSetEditForm < Hyrax::Forms::FileSetEditForm
    self.terms += [:pcdm_use]
  end
end
