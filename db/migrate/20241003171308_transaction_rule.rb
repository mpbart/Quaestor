class TransactionRule < ActiveRecord::Migration[7.1]
  def change
    create_table :transaction_rules do |t|
      t.string :field_name_to_replace
      t.string :replacement_value

      t.timestamps
    end
  end
end
