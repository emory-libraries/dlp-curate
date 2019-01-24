class AddPpidToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :ppid, :string
  end
end
