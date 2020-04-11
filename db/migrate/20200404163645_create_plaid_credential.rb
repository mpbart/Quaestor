class CreatePlaidCredential < ActiveRecord::Migration[6.0]
  def change
    create_table :plaid_credentials do |t|
      t.references :user
      t.string     :plaid_item
      t.jsonb      :parameters

      t.timestamps
    end
  end
end
