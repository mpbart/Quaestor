class AddCursorToPlaidCredential < ActiveRecord::Migration[7.1]
  def change
    add_column :plaid_credentials, :cursor, :string
  end
end
