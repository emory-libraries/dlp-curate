module Curate::Forms
  class FileSetEditForm < Hyrax::Forms::FileSetEditForm
    self.terms += [:pcdm_use]
  end
end
