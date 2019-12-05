class AddPreferredToJobiowrapper < ActiveRecord::Migration[5.1]
  def change
    add_column :job_io_wrappers, :preferred, :string
  end
end
