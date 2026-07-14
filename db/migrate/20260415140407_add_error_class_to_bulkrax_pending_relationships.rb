# frozen_string_literal: true

class AddErrorClassToBulkraxPendingRelationships < ActiveRecord::Migration[6.1]
  def change
    add_column :bulkrax_pending_relationships, :error_class, :string unless column_exists?(:bulkrax_pending_relationships, :error_class)
  end
end
