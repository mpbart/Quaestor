# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_08_28_000000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_stat_statements"
  enable_extension "pgcrypto"

  create_table "accounts", force: :cascade do |t|
    t.string "account_sub_type"
    t.string "account_type"
    t.datetime "created_at", null: false
    t.boolean "inactive", default: false
    t.string "institution_id"
    t.string "institution_name"
    t.string "mask"
    t.string "name"
    t.string "official_name"
    t.string "plaid_identifier"
    t.datetime "updated_at", null: false
    t.integer "user_id"
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.string "content_type"
    t.datetime "created_at", precision: nil, null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", default: "local", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "idx_on_blob_id_variation_digest_f36bede0d9", unique: true
  end

  create_table "balances", force: :cascade do |t|
    t.bigint "account_id"
    t.float "amount"
    t.float "available"
    t.datetime "created_at", null: false
    t.boolean "interpolated", default: false
    t.float "limit"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_balances_on_account_id"
  end

  create_table "google_drive_credentials", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "encrypted_key_hash"
    t.string "encrypted_key_hash_iv"
    t.string "encrypted_refresh_token"
    t.string "encrypted_refresh_token_iv"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["user_id"], name: "index_google_drive_credentials_on_user_id"
  end

  create_table "labels", force: :cascade do |t|
    t.string "name"
  end

  create_table "labels_transactions", id: false, force: :cascade do |t|
    t.bigint "label_id", null: false
    t.string "transaction_id", null: false
    t.index ["label_id", "transaction_id"], name: "index_labels_transactions_on_label_id_and_transaction_id", unique: true
    t.index ["label_id"], name: "index_labels_transactions_on_label_id"
    t.index ["transaction_id"], name: "index_labels_transactions_on_transaction_id"
  end

  create_table "plaid_categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description"
    t.string "detailed_category"
    t.string "primary_category"
    t.datetime "updated_at", null: false
  end

  create_table "plaid_credentials", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "cursor"
    t.string "encrypted_access_token"
    t.string "encrypted_access_token_iv"
    t.string "institution_id"
    t.string "institution_name"
    t.string "plaid_item_id"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["encrypted_access_token_iv"], name: "index_plaid_credentials_on_encrypted_access_token_iv", unique: true
    t.index ["user_id"], name: "index_plaid_credentials_on_user_id"
  end

  create_table "plaid_responses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "encrypted_response"
    t.string "encrypted_response_iv"
    t.string "endpoint"
    t.bigint "plaid_credential_id", null: false
    t.datetime "updated_at", null: false
    t.index ["encrypted_response_iv"], name: "index_plaid_responses_on_encrypted_response_iv"
    t.index ["plaid_credential_id"], name: "index_plaid_responses_on_plaid_credential_id"
  end

  create_table "rule_criteria", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "field_name"
    t.string "field_qualifier"
    t.bigint "transaction_rule_id"
    t.datetime "updated_at", null: false
    t.string "value_comparator"
    t.index ["transaction_rule_id"], name: "index_rule_criteria_on_transaction_rule_id"
  end

  create_table "transaction_groups", primary_key: "uuid", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "transaction_rules", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "field_replacement_mappings"
    t.decimal "split_amount", precision: 10, scale: 2
    t.integer "split_category_id"
    t.string "split_description"
    t.jsonb "split_labels", default: []
    t.string "split_merchant_name"
    t.datetime "updated_at", null: false
  end

  create_table "transactions", id: :string, force: :cascade do |t|
    t.bigint "account_id"
    t.string "account_owner"
    t.float "amount"
    t.string "category_confidence"
    t.datetime "created_at", null: false
    t.datetime "date", precision: nil
    t.datetime "deleted_at"
    t.string "description"
    t.jsonb "location_metadata"
    t.string "merchant_name"
    t.string "payment_channel"
    t.jsonb "payment_metadata"
    t.boolean "pending"
    t.string "pending_transaction_id"
    t.bigint "plaid_category_id"
    t.boolean "split", default: false
    t.uuid "transaction_group_uuid"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["account_id"], name: "index_transactions_on_account_id"
    t.index ["date"], name: "index_transactions_on_date"
    t.index ["deleted_at"], name: "index_transactions_on_deleted_at"
    t.index ["id"], name: "index_transactions_on_id"
    t.index ["plaid_category_id"], name: "index_transactions_on_plaid_category_id"
    t.index ["transaction_group_uuid"], name: "index_transactions_on_transaction_group_uuid"
    t.index ["user_id"], name: "index_transactions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at", precision: nil
    t.inet "current_sign_in_ip"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "last_sign_in_at", precision: nil
    t.inet "last_sign_in_ip"
    t.datetime "remember_created_at", precision: nil
    t.datetime "reset_password_sent_at", precision: nil
    t.string "reset_password_token"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "plaid_responses", "plaid_credentials"
end
