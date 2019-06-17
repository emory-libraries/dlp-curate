class AddFileTypesToUploadedFiles < ActiveRecord::Migration[5.1]
  def change
  	# add columns
  	add_column :uploaded_files, :preservation_master_file, :string
  	add_column :uploaded_files, :intermediate_file, :string
  	add_column :uploaded_files, :service_file, :string
  	add_column :uploaded_files, :extracted_text, :string
  	add_column :uploaded_files, :transcript, :string

  	# drop column
  	remove_column :uploaded_files, :file_type
  end
end
