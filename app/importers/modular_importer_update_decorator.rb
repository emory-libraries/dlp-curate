# frozen_string_literal: true

module ModularImporterUpdateDecorator
  def metadata_only_attach_files(super_method)
    super_method unless related_rows.empty?
    super_method if existing_work.first.file_sets.empty?
  end

  def attach_files
    case csv_import.update_actor_stack
    when 'HyraxMetadataOnly'
      metadata_only_attach_files(super)
    when 'HyraxOnlyNew'
      super if existing_work.first.file_sets.empty?
    else
      super
    end
  end

  def save_work
    case csv_import.update_actor_stack
    when 'HyraxMetadataOnly'
      if existing_work.empty?
        super
      else
        existing_work.first.update_attributes!(work_metadata)
        @work_id = existing_work.first.id
      end
    when 'HyraxOnlyNew'
      super if existing_work.first.try(:file_sets).nil?
    else
      existing_work.first.delete
      super
    end
  end
end
