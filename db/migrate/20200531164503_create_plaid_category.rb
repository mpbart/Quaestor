class CreatePlaidCategory < ActiveRecord::Migration[6.0]
  def change
    create_table :plaid_categories do |t|
      t.jsonb :hierarchy
      t.string :category_id

      t.timestamps
    end
  end
end
