# frozen_string_literal: true

# Values for the `model` column of preprocessed Bulkrax CSVs. During the Valkyrie
# transition Bulkrax imports into the Valkyrie models, so rows must name them.
module PreprocessorModelNames
  def work_model_name
    Hyrax.config.valkyrie_transition? ? 'CurateGenericWorkResource' : 'CurateGenericWork'
  end

  def file_set_model_name
    Hyrax.config.valkyrie_transition? ? 'FileSetResource' : 'FileSet'
  end
end
