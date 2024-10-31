class ChangeTransactionRulesColumns < ActiveRecord::Migration[7.1]
  def change
    remove_column :transaction_rules, :field_name_to_replace, :string
    remove_column :transaction_rules, :replacement_value, :string

    add_column :transaction_rules, :field_replacement_mappings, :jsonb
  end
end
