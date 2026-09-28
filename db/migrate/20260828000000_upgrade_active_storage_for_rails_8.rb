# frozen_string_literal: true

class UpgradeActiveStorageForRails8 < ActiveRecord::Migration[7.2]
  def change
    add_column :active_storage_blobs, :service_name, :string, null: false, default: 'local'

    create_table :active_storage_variant_records do |t|
      t.belongs_to :blob, null: false, index: false
      t.string :variation_digest, null: false

      t.index %i[blob_id variation_digest], unique: true
      t.foreign_key :active_storage_blobs, column: :blob_id
    end
  end
end
