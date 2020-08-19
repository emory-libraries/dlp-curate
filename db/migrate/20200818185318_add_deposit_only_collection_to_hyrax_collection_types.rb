class AddDepositOnlyCollectionToHyraxCollectionTypes < ActiveRecord::Migration[5.1]
  def up
    unless column_exists?(:hyrax_collection_types, :deposit_only_collection)
      add_column :hyrax_collection_types, :deposit_only_collection, :boolean, null: false, default: false
    end
  end

  def down
    if column_exists?(:hyrax_collection_types, :deposit_only_collection)
      remove_column :hyrax_collection_types, :deposit_only_collection
    end
  end
end
