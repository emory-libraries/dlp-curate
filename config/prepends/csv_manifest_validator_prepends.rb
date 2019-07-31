module CsvManifestValidatorPrepends
  def valid_headers
    ['title', 'source', 'visibility']
  end

  def required_headers
    ['title', 'source']
  end
end
