# frozen_string_literal: true

# This module will be used to define methods that will associate filesets with works
module AssociateFilesetsWithWorks
  def pull_file_set_entries(importer:)
    # Sorted by id, the order Bulkrax created them in: the order of the CSV rows.
    entries_to_return = importer.entries.select { |e| e.factory_class == FileSet || e.factory_class == FileSetResource }.sort_by(&:id)
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
      check_work_for_errant_member_ids(work)
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
    expected_entries = pull_fileset_entries_for_parent(work.deduplication_key).reject { |entry| import_given_up?(entry) }
    raise "All FileSetResources haven't been persisted yet" if file_sets.size < expected_entries.size

    # The Valkyrie importer attaches each FileSet to the work as soon as its job finishes,
    # so the members are in completion order (and may be duplicated) rather than CSV order.
    ordered_ids = ordered_member_ids(work, file_sets)
    return if ordered_ids == work.member_ids.map(&:to_s)

    # Reindexes the members and regenerates the manifest in the new order.
    ReplaceWorkMembersJob.perform_now(work, ordered_ids)
  end

  # The imported FileSets follow the order of their CSV rows; members that did not come from
  # this import keep their place ahead of them. Duplicate and nil members are dropped.
  def ordered_member_ids(work, file_sets)
    imported_ids = file_sets.map { |fs| fs.id.to_s }
    (work.member_ids.compact.map(&:to_s).uniq - imported_ids) + imported_ids
  end

  # ImportFileSetJob stopped retrying these entries, so their FileSets will never be created.
  def import_given_up?(entry)
    entry.failed? && entry.import_attempts.to_i >= ENV.fetch("IMPORT_FILE_SET_RETRIES", 8).to_i
  end

  def announce_filesets_attachement(file_sets)
    file_sets.each { |fs| Hyrax.config.callback.run(:after_create_fileset, fs, ::User.find_by(uid: fs.depositor)) }
  end

  def file_set_entry_parents_present?(fileset_entries:)
    fileset_entries&.all? { |fse| fse&.parsed_metadata&.[]('parent')&.present? }
  end

  def check_work_for_errant_member_ids(work)
    reloaded_work = pull_work(work.id.to_s)

    ReplaceWorkMembersJob.perform_later(reloaded_work, reloaded_work.cleaned_member_ids) if reloaded_work.duplicated_or_nil_member_ids?
  end
end
