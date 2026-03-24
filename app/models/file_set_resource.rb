# frozen_string_literal: true

class FileSetResource < Hyrax::FileSet
  PRIMARY = 'Primary Content'
  SUPPLEMENTAL = 'Supplemental Content'
  PRESERVATION = 'Supplemental Preservation'

  include Hyrax::Schema(:emory_file_set_metadata)
end
