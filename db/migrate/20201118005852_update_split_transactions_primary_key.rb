class UpdateSplitTransactionsPrimaryKey < ActiveRecord::Migration[6.0]
  def change
    enable_extension 'pgcrypto'

    remove_column :split_transactions, :id
    add_column :split_transactions, :uuid, :uuid, default: -> { "gen_random_uuid()" }, primary_key: true
  end
end
