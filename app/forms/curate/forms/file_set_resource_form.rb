# frozen_string_literal: true

# Valkyrie form for FileSetResource.
# Mirrors the AF Curate::Forms::FileSetEditForm with pcdm_use support.
module Curate
  module Forms
    class FileSetResourceForm < Hyrax::Forms::FileSetForm
      include Hyrax::FormFields(:emory_file_set_metadata)
    end
  end
end
