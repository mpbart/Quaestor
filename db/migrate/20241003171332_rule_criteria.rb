class RuleCriteria < ActiveRecord::Migration[7.1]
  def change
    create_table :rule_criteria do |t|
      t.references :transaction_rule
      t.string :field_name
      t.string :field_qualifier
      t.string :value_comparator

      t.timestamps
    end
  end
end
