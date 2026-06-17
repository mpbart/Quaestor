class AddInactiveToAccounts < ActiveRecord::Migration[7.1]
  def change
    add_column :accounts, :inactive, :boolean, default: false
  end
end
