class AddEncryptionToPlaidCredential < ActiveRecord::Migration[6.0]
  def change
    remove_column :plaid_credentials, :access_token, :string
    add_column    :plaid_credentials, :encrypted_access_token, :string
    add_column    :plaid_credentials, :encrypted_access_token_iv, :string

    add_index :plaid_credentials, :encrypted_access_token_iv, unique: true
  end
end
