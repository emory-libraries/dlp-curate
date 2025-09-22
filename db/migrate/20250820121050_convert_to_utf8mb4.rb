class ConvertToUtf8mb4 < ActiveRecord::Migration[5.2]
  def change
    if Rails.env.production?
      # Change database encoding
      execute "ALTER DATABASE `#{ActiveRecord::Base.connection.current_database}` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

      # Change table and column encoding
      ActiveRecord::Base.connection.tables.each do |table_name|
        execute "ALTER TABLE `#{table_name}` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
      end
    end
  end
end
