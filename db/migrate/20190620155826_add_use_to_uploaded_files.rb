class AddUseToUploadedFiles < ActiveRecord::Migration[5.1]
  def change
  	add_column :uploaded_files, :fileset_use, :string
  end
end
