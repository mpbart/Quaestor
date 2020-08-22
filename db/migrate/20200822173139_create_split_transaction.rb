class CreateSplitTransaction < ActiveRecord::Migration[6.0]
  def change
    create_table :split_transactions do |t|
      t.references :transaction, type: :string

      t.float :amount
      t.datetime :date
      t.string :description
      t.string :category, array: true
      t.integer :category_id
      t.timestamps
    end
  end
end
