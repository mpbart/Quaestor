class UpdateTransactionColumns < ActiveRecord::Migration[7.1]
  def change
    add_column :transactions, :primary_category, :string
    add_column :transactions, :detailed_category, :string
    add_column :transactions, :category_confidence, :string
    add_column :transactions, :merchant_name, :string
    add_column :transactions, :deleted_at, :datetime

    remove_column :transactions, :category_id
    remove_column :transactions, :category
    remove_column :transactions, :id

    rename_column :transactions, :transaction_type, :payment_channel

    add_column :transactions, :id, :string, primary_key: true

    add_index :transactions, :deleted_at
  end
end
