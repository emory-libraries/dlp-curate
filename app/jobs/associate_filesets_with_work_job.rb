# frozen_string_literal: true

class AssociateFilesetsWithWorkJob < Hyrax::ApplicationJob
  queue_as :import

  def perform(importer)
    file_set_entries = pull_file_set_entries(importer)
    parents = pull_parents(file_set_entries)

    process_file_sets(parents, file_set_entries)
  end

  def pull_file_set_entries(importer)
    entries_to_return = importer.entries.select { |e| e.factory_class == FileSet }
    raise 'The are no FileSet entries to iterate over' if entries_to_return.blank?
    entries_to_return
  end

  def pull_parents(file_set_entries)
    file_set_entries.map { |e| e.parsed_metadata['parent'] }.compact.uniq.flatten
  end

  def pull_work(parent)
    parent.include?('-cor') ? CurateGenericWork.find(parent) : CurateGenericWork.where(deduplication_key: [parent])&.first
  end

  def pull_fileset_entries_for_parent(file_set_entries, parent)
    file_set_entries.select { |fse| fse.parsed_metadata['parent'] == [parent] }
  end

  def pull_file_sets(file_set_entries, parent)
    pull_fileset_entries_for_parent(file_set_entries, parent).map { |v| v&.factory&.find }.compact
  end

  def process_file_sets(parents, file_set_entries)
    raise "There are no parents to iterate over" if parents.blank?

    parents.each do |p|
      work = pull_work(p)
      file_sets = pull_file_sets(file_set_entries, p)
      raise 'A CurateGenericWork and/or FileSet objects could not be found' unless work.present? && file_sets.present?

      work.ordered_members += file_sets
      work.save

      file_sets.each { |fs| Hyrax.config.callback.run(:after_create_fileset, fs, ::User.find_by(uid: fs.depositor)) }
    end
  end
end
