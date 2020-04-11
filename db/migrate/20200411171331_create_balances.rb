class CreateBalances < ActiveRecord::Migration[6.0]
  def change
    create_table :balances do |t|
      t.references :account
      t.float      :amount
      t.float      :available
      t.float      :limit

      t.timestamps
    end
  end
end
