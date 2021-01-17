class CreateTransactionGroup < ActiveRecord::Migration[6.0]
  def change
    create_table :transaction_groups, id: false do |t|
      enable_extension 'pgcrypto'

      t.uuid :uuid, default: -> { "gen_random_uuid()" }, primary_key: true
      t.timestamps
    end

    add_column :transactions, :transaction_group_uuid, :uuid
    add_index :transactions, :transaction_group_uuid
  end
end
