# frozen_string_literal: true

module FileSetMethods
  def process_uploaded_file(work_permissions, file_set_attrs)
    actor = ::Hyrax::Actors::FileSetActor.new(object, @user)

    @uploaded_file.add_file_set!(actor.file_set)
    actor.file_set.permissions_attributes = work_permissions
    actor.create_metadata(@uploaded_file.fileset_use, file_set_attrs)
    actor.fileset_name(@uploaded_file.file.to_s) if @uploaded_file.file.present?
    create_content_for_actor(actor, @uploaded_file)
    actor.file_set.save
    actor.attach_to_work(@work, file_set_attrs)
  end

  def create_content_for_actor(actor, uploaded_file)
    actor.create_content(uploaded_file.preservation_master_file, @preferred, :preservation_master_file) if uploaded_file.preservation_master_file.present?
    actor.create_content(uploaded_file.intermediate_file, @preferred, :intermediate_file) if uploaded_file.intermediate_file.present?
    actor.create_content(uploaded_file.service_file, @preferred, :service_file) if uploaded_file.service_file.present?
    actor.create_content(uploaded_file.extracted_text, @preferred, :extracted) if uploaded_file.extracted_text.present?
    actor.create_content(uploaded_file.transcript, @preferred, :transcript_file) if uploaded_file.transcript.present?
  end

  def preferred_file(uploaded_files)
    preferred = if uploaded_files.any? { |uf| uf&.service_file&.present? }
                  :service_file
                elsif uploaded_files.any? { |uf| uf&.intermediate_file&.present? }
                  :intermediate_file
                else
                  :preservation_master_file
                end
    preferred
  end

  def process_file_types(file_name)
    raw_strings = parser.file_sets.map { |v| v[:file_types] }&.compact
    split_strings = raw_strings.map { |rs| rs.split('|') }&.flatten
    string_type_hashes = process_string_type_hashes(split_strings)
    pulled_hash = string_type_hashes.select { |h| h[file_name].present? }&.first

    pulled_hash[file_name] || "preservation_master_file"
  end

  def process_string_type_hashes(split_strings)
    split_strings.map do |ss|
      pieces = ss.split(':')
      { pieces[0].to_s => pieces[1] }
    end
  end

  def process_multiple_file_export(file_sets, folder_count)
    file_sets.each { |fileset| process_export_fileset_files(fileset, folder_count) }
  end

  def process_export_fileset_files(fileset, folder_count)
    path = export_file_path(folder_count)
    FileUtils.mkdir_p(path) unless File.exist? path
    files = filename(fileset)&.split(';')
    return if files.empty?

    shovel_files_into_folder(files, fileset, path)
  end

  def shovel_files_into_folder(files, file_set, path)
    files.each do |file|
      file_split = file.split(':')
      io = open(file_set.send(file_split.last).uri)
      File.open(File.join(path, file_split.first), 'wb') do |f|
        f.write(io.read)
        f.close
      end
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
end
