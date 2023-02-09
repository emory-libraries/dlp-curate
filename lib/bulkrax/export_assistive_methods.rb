# frozen_string_literal: true
module ExportAssistiveMethods
  def process_multiple_file_export(file_sets, folder_count)
    file_sets.each { |fileset| process_export_fileset_files(fileset, folder_count) }
  end

  def process_export_fileset_files(fileset, folder_count)
    path = export_file_path(folder_count)
    FileUtils.mkdir_p(path) unless File.exist? path
    files = filename(fileset)&.split('|')
    return if files.empty?

    shovel_files_into_folder(files, fileset, path)
  end

  def shovel_files_into_folder(files, file_set, path)
    files.each do |file|
      file_split = file.split(':')
      file_name = file_split.first
      file_type = convert_setter_to_fileset_getter(file_split.last)
      io = open(file_set.send(file_type).uri)

      File.open(File.join(path, file_name), 'wb') do |f|
        f.write(io.read)
        f.close
      end
    end
  end

  def convert_setter_to_fileset_getter(setter)
    case setter
    when 'extracted_text'
      'extracted'
    when 'transcript'
      'transcript_file'
    else
      setter
    end
  end

  def pull_export_filesets(record)
    record.file_set? ? Array.wrap(record) : record.file_sets
  end

  def export_file_path(folder_count)
    File.join(exporter_export_path, folder_count, 'files')
  end

  def process_model_to_write(entries_to_write, model)
    entries_to_write.map.with_index do |e, ind|
      e.parsed_metadata['model'] == model ? ind : nil
    end.compact
  end

  def process_filesets_to_write(entries_to_write, work_id)
    entries_to_write.map.with_index do |e, ind|
      e.parsed_metadata['model'] == 'FileSet' && e.parsed_metadata['parent'] == work_id ? ind : nil
    end.compact
  end

  def process_filesets_and_work_to_write(entries_to_write)
    work_file_set_grouping = []
    works_in_entries = process_model_to_write(entries_to_write, 'CurateGenericWork')

    works_in_entries.each do |w|
      work_id = entries_to_write[w].identifier

      file_set_indexes = process_filesets_to_write(entries_to_write, work_id)

      work_file_set_grouping += ([w] + file_set_indexes)
    end

    work_file_set_grouping
  end

  def sort_entries_to_write(entries_to_write)
    collections_to_write = process_model_to_write(entries_to_write, 'Collection')

    work_file_set_grouping = process_filesets_and_work_to_write(entries_to_write)

    sorted_order = collections_to_write + work_file_set_grouping
    entries_to_write.values_at(*sorted_order)
  end

  def process_current_record_object_ids
    ids = importerexporter.export_source.split('|')

    ids.each do |id|
      record = ActiveFedora::Base.find(id)

      if record.is_a?(Collection)
        @collection_ids += [id]
      elsif record.is_a?(CurateGenericWork)
        @work_ids += [id]
      end
    end
    find_child_file_sets(@work_ids)
  end

  def build_preservation_workflow_metadata
    work_pres_workflows = hyrax_record.preservation_workflow
    return if work_pres_workflows.blank?

    work_pres_workflows.each do |workflow|
      type = workflow.workflow_type.first
      workflow_attrs = %w[workflow_notes workflow_rights_basis workflow_rights_basis_note workflow_rights_basis_date workflow_rights_basis_reviewer workflow_rights_basis_uri]

      workflow_attrs.each do |attrib|
        handle_join_on_export("#{type}.#{attrib}", workflow.send(attrib.to_sym).to_a, '|')
      end
    end
  end

  def build_triples_value(key, value, data)
    if value['join']
      triples_values_joined(key, value, data)
    else
      data.each_with_index do |d, i|
        parsed_metadata["#{key_for_export(key)}_#{i + 1}"] = prepare_export_data(d)
      end
    end
  end

  def triples_values_joined(key, value, data)
    processed_value = key == 'creator' && hyrax_record.is_a?(FileSet) ? nil : data.map { |d| prepare_export_data(d) }.join(value['join']).to_s
    parsed_metadata[key_for_export(key)] = processed_value
  end
end
