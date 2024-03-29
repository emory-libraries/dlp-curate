# frozen_string_literal: true

# Deprecation Warning: As of Curate v3, Zizia will be removed. This is an artifact
#   of the Zizia install that will likely be removed.
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
        existing_work.first.update!(work_metadata)
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
