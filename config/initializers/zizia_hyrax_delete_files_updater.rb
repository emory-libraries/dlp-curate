# frozen_string_literal: true

Zizia::HyraxDeleteFilesUpdater.class_eval do
  def update
    existing_record.file_sets.map(&:destroy)
    if actor_stack.update(create_actor_env)
      csv_import_detail.success_count += 1
    else
      existing_record.errors.each do |attr, _msg|
        failed(attr)
      end
      csv_import_detail.failure_count += 1
    end
    csv_import_detail.save
  end
end
