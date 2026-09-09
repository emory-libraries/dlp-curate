# frozen_string_literal: true

# This module will be used to define methods that will associate filesets with works
module AssociateFilesetsWithWorks
  def pull_file_set_entries(importer:)
    entries_to_return = importer.entries.select { |e| e.factory_class == FileSet }
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

  def pull_fileset_entries_for_parent(file_set_entries, parent)
    file_set_entries.select { |fse| fse.parsed_metadata['parent'] == [parent] }
  end

  def pull_file_sets(file_set_entries, parent)
    pull_fileset_entries_for_parent(file_set_entries, parent).map { |v| v&.factory&.find&.presence }.compact.uniq
  end

  def process_file_sets(parents:, file_set_entries:)
    parents.each do |p|
      work = pull_work(p)
      file_sets = pull_file_sets(file_set_entries, p)
      raise 'A CurateGenericWork and/or FileSet objects could not be found' unless work.present? && file_sets.present?

      associate_filesets_to_work(file_sets, work)
      announce_filesets_attachement(file_sets)
    end
  end

  def associate_filesets_to_work(file_sets, work)
    case work
    when Hyrax::Resource
      associate_valkyrie(file_sets, work)
    else
      associate_af(file_sets, work)
    end
  end

  def associate_af(file_sets, work)
    return if file_sets&.map(&:id)&.all? { |id| work.reload.ordered_member_ids.include?(id) }
    work.ordered_members += file_sets
    work.save
  end

  def associate_valkyrie(file_sets, work)
    existing_ids = work.member_ids.map(&:to_s)
    new_ids = file_sets.map { |fs| fs.id.to_s } - existing_ids
    return if new_ids.empty?

    work.member_ids += new_ids.map { |id| Valkyrie::ID.new(id) }
    Hyrax.persister.save(resource: work)
    Hyrax.index_adapter.save(resource: work)
  end

  def announce_filesets_attachement(file_sets)
    file_sets.each { |fs| Hyrax.config.callback.run(:after_create_fileset, fs, ::User.find_by(uid: fs.depositor)) }
  end

  def file_set_entry_parents_present?(file_set_entries:)
    file_set_entries&.all? { |fse| fse&.parsed_metadata&.[]('parent')&.present? }
  end
end
