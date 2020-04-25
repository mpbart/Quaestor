class CreatePlaidResponses < ActiveRecord::Migration[6.0]
  def change
    create_table :plaid_responses do |t|
      t.string :encrypted_response
      t.string :encrypted_response_iv
      t.string :endpoint
      t.references :plaid_credential, null: false, foreign_key: true

      t.timestamps
    end

    add_index :plaid_responses, :encrypted_response_iv
  end
end
