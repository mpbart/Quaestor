class DeleteSplitTransaction < ActiveRecord::Migration[6.0]
  def change
    drop_table :split_transactions
  end
end
