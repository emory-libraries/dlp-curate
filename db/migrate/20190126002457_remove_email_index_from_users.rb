class RemoveEmailIndexFromUsers < ActiveRecord::Migration[5.1]
  def change
  	remove_index :users, :email
  end
end
