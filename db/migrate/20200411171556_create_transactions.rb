class CreateTransactions < ActiveRecord::Migration[6.0]
  def change
    create_table :transactions do |t|
      t.references :account
      t.references :user

      t.string     :category, array: true
      t.string     :category_id
      t.string     :transaction_type
      t.string     :description
      t.float      :amount
      t.datetime   :date
      t.boolean    :pending
      t.jsonb      :payment_metadata
      t.jsonb      :location_metadata
      t.string     :pending_transaction_id
      t.string     :account_owner

      t.timestamps
    end
  end
end
