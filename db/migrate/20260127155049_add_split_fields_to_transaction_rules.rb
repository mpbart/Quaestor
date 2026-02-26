class AddSplitFieldsToTransactionRules < ActiveRecord::Migration[7.1]
  def change
    add_column :transaction_rules, :split_category_id, :integer
    add_column :transaction_rules, :split_amount, :decimal, precision: 10, scale: 2
    add_column :transaction_rules, :split_description, :string
    add_column :transaction_rules, :split_merchant_name, :string
    add_column :transaction_rules, :split_labels, :jsonb, default: []
  end
end
