class AddBannerToUploadedFiles < ActiveRecord::Migration[5.1]
  def change
    add_column :uploaded_files, :collection_banner, :string
  end
end
