# frozen_string_literal: true

# This module will be used to define methods that will associate filesets with works
module AssociateFilesetsWithWorks
  def pull_file_set_entries(importer:)
    entries_to_return = importer.entries.select { |e| e.factory_class == FileSet || e.factory_class == FileSetResource }
    raise 'The are no FileSet entries to iterate over' if entries_to_return.blank?
    entries_to_return
  end

  def pull_parents(file_set_entries:)
    parents_to_return = file_set_entries&.map { |e| e&.parsed_metadata&.[]('parent') }&.compact&.uniq&.flatten
    raise "There are no parents to iterate over" if parents_to_return.blank?
    parents_to_return
  end

  def pull_work(parent)
    if Hyrax.config.valkyrie_transition?
      find_work_valkyrie(parent)
    else
      find_work_af(parent)
    end
  end

  def find_work_af(parent)
    CurateGenericWork.find(parent)
  rescue StandardError
    CurateGenericWork.where(deduplication_key: [parent])&.first
  end

  def find_work_valkyrie(parent)
    Hyrax.query_service.find_by(id: parent)
  rescue Valkyrie::Persistence::ObjectNotFoundError
    results = Hyrax::SolrService.query("deduplication_key_tesim:#{parent}", rows: 1, fl: "id")
    return nil if results.blank?
    Hyrax.query_service.find_by(id: results.first["id"])
  end

  def pull_fileset_entries_for_parent(parent)
    @file_set_entries.select { |fse| fse.parsed_metadata['parent'] == [parent] }
  end

  def pull_file_sets(parent)
    pull_fileset_entries_for_parent(parent).map { |v| v&.factory&.find&.presence }.compact.uniq
  end

  def process_file_sets(parents:, file_set_entries:)
    @file_set_entries = file_set_entries

    parents.each do |p|
      work = pull_work(p)
      file_sets = pull_file_sets(p)
      raise 'A CurateGenericWork and/or FileSet objects could not be found' unless work.present? && file_sets.present?

      associate_filesets_to_work(work, file_sets)
      announce_filesets_attachement(file_sets)
    end
  end

  def associate_filesets_to_work(work, file_sets)
    case work
    when Hyrax::Resource
      associate_valkyrie(work, file_sets)
    else
      associate_af(work, file_sets)
    end
  end

  def associate_af(work, file_sets)
    return if file_sets&.map(&:id)&.all? { |id| work.reload.ordered_member_ids.include?(id) }

    work.ordered_members += file_sets
    work.save
  end

  def associate_valkyrie(work, file_sets)
    raise "All FileSetResources haven't been persisted yet" unless pull_fileset_entries_for_parent(work.deduplication_key).size == file_sets.size

    work.member_ids = file_sets.map(&:id)
    Hyrax.persister.save(resource: work)
    Hyrax.index_adapter.save(resource: work)
  end

  def announce_filesets_attachement(file_sets)
    file_sets.each { |fs| Hyrax.config.callback.run(:after_create_fileset, fs, ::User.find_by(uid: fs.depositor)) }
  end

  def file_set_entry_parents_present?(fileset_entries:)
    fileset_entries&.all? { |fse| fse&.parsed_metadata&.[]('parent')&.present? }
  end
end
