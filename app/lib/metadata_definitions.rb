# frozen_string_literal: true

module MetadataDefinitions
  def preservation_master_file_definition
    {
      attribute:  'preservation_master_file',
      predicate:  'n/a',
      multiple: 	'false',
      type:       'String',
      validator: 	'Required, must name a file on the server',
      label: 	    'Preservation Master File',
      csv_header: 'preservation_master_file',
      required_on_form: 	'true',
      usage: Zizia::MetadataUsage.instance.usage['preservation_master_file']
    }
  end

  def intermediate_file_definition
    {
      attribute:  'intermediate_file',
      predicate:  'n/a',
      multiple: 	'false',
      type:       'String',
      validator: 	'Not Required',
      label: 	    'Intermediate File',
      csv_header: 'intermediate_file',
      required_on_form: 	'false',
      usage: Zizia::MetadataUsage.instance.usage['intermediate_file']
    }
  end

  def service_file_definition
    {
      attribute:  'service_file',
      predicate:  'n/a',
      multiple: 	'false',
      type:       'String',
      validator: 	'Not Required',
      label: 	    'Service File',
      csv_header: 'service_file',
      required_on_form: 	'false',
      usage: Zizia::MetadataUsage.instance.usage['service_file']
    }
  end

  def extracted_definition
    {
      attribute:  'extracted',
      predicate:  'n/a',
      multiple: 	'false',
      type:       'String',
      validator: 	'Not Required',
      label: 	    'Extracted Text',
      csv_header: 'extracted',
      required_on_form: 	'false',
      usage: Zizia::MetadataUsage.instance.usage['extracted']
    }
  end

  def transcript_definition
    {
      attribute:  'transcript',
      predicate:  'n/a',
      multiple: 	'false',
      type:       'String',
      validator: 	'',
      label: 	    'Not Required',
      csv_header: 'transcript',
      required_on_form: 	'false',
      usage: Zizia::MetadataUsage.instance.usage['transcript']
    }
  end

  def fileset_label_definition
    {
      attribute:  'fileset_label',
      predicate:  'n/a',
      multiple: 	'false',
      type:       'String',
      validator: 	'Not Required',
      label: 	    'FileSet Label',
      csv_header: 'fileset_label',
      required_on_form: 	'true',
      usage: Zizia::MetadataUsage.instance.usage['fileset_label']
    }
  end

  def pcdm_use_definition
    {
      attribute:  'pcdm_use',
      predicate:  'n/a',
      multiple: 	'false',
      type:       'String',
      validator: 	'Not Required',
      label: 	    'FileSet use',
      csv_header: 'pcdm_use',
      required_on_form: 	'false',
      usage: Zizia::MetadataUsage.instance.usage['pcdm_use']
    }
  end
end
