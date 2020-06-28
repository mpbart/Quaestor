class AddSplitToTransaction < ActiveRecord::Migration[6.0]
  def change
    add_column :transactions, :split, :bool, default: false
  end
end
