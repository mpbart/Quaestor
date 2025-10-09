class AddGoogleCredentials < ActiveRecord::Migration[7.1]
  def change
    create_table :google_drive_credentials do |t|
      t.references :user
      t.string    :encrypted_key_hash
      t.string    :encrypted_key_hash_iv
      t.string    :encrypted_refresh_token
      t.string    :encrypted_refresh_token_iv

      t.timestamps
    end
  end

  def down
    drop_table :google_drive_credentials
  end
end
