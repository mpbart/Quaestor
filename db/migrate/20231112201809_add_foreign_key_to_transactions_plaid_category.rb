class AddForeignKeyToTransactionsPlaidCategory < ActiveRecord::Migration[7.1]
  def change
    add_reference :transactions, :plaid_category

    add_index :transactions, :id

    remove_column :transactions, :primary_category
    remove_column :transactions, :detailed_category
  end
end
