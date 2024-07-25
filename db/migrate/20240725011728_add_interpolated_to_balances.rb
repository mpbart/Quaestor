class AddInterpolatedToBalances < ActiveRecord::Migration[7.1]
  def change
    add_column :balances, :interpolated, :bool, default: false
  end
end
