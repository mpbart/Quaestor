class CreateAccount < ActiveRecord::Migration[6.0]
  def change
    create_table :accounts do |t|
      t.string  :name
      t.string  :plaid_identifier
      t.integer :user_id
      t.string  :official_name
      t.string  :account_type
      t.string  :account_sub_type
      t.string  :mask

      t.timestamps
    end
  end
end
