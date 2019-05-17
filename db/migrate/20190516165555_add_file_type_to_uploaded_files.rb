class AddFileTypeToUploadedFiles < ActiveRecord::Migration[5.1]
  def change
  	add_column :uploaded_files, :file_type, :string
  end
end
