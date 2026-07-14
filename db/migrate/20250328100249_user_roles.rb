# frozen_string_literal: true

class UserRoles < ActiveRecord::Migration[5.0]
  def up
    create_table :roles do |t|
      t.string :name
    end unless table_exists?(:roles)
    create_table :roles_users, id: false do |t|
      t.references :role
      t.references :user
    end unless table_exists?(:roles_users)
    add_index :roles_users, %i[role_id user_id] unless index_exists?(:roles_users, [:role_id, :user_id], name: 'index_roles_users_on_role_id_and_user_id')
    add_index :roles_users, %i[user_id role_id] unless index_exists?(:roles_users, [:user_id, :role_id], name: 'index_roles_users_on_user_id_and_role_id')
  end

  def down
    drop_table :roles_users
    drop_table :roles
  end
end
