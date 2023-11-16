class CreateTransactionsLabelsJoinTable < ActiveRecord::Migration[7.1]
  def change
    create_table :labels do |t|
      t.string :name
    end

    create_table :labels_transactions, id: false do |t|
      t.string :transaction_id, null: false
      t.bigint :label_id, null: false

      t.index [:label_id, :transaction_id], unique: true
      t.index :label_id
      t.index :transaction_id
    end
  end
end
