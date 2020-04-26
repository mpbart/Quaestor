class UpdateIdsToString < ActiveRecord::Migration[6.0]
  def change
    change_column :transactions, :id, :string, index: true, primary_key: true
  end
end
