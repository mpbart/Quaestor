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

ActiveRecord::Schema[7.1].define(version: 2023_11_12_194101) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.string "name"
    t.string "plaid_identifier"
    t.integer "user_id"
    t.string "official_name"
    t.string "account_type"
    t.string "account_sub_type"
    t.string "mask"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "institution_name"
    t.string "institution_id"
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", precision: nil, null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "balances", force: :cascade do |t|
    t.bigint "account_id"
    t.float "amount"
    t.float "available"
    t.float "limit"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_balances_on_account_id"
  end

  create_table "plaid_categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "primary_category"
    t.string "detailed_category"
    t.string "description"
  end

  create_table "plaid_credentials", force: :cascade do |t|
    t.bigint "user_id"
    t.string "plaid_item_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "encrypted_access_token"
    t.string "encrypted_access_token_iv"
    t.string "institution_name"
    t.string "institution_id"
    t.string "cursor"
    t.index ["encrypted_access_token_iv"], name: "index_plaid_credentials_on_encrypted_access_token_iv", unique: true
    t.index ["user_id"], name: "index_plaid_credentials_on_user_id"
  end

  create_table "plaid_responses", force: :cascade do |t|
    t.string "encrypted_response"
    t.string "encrypted_response_iv"
    t.string "endpoint"
    t.bigint "plaid_credential_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["encrypted_response_iv"], name: "index_plaid_responses_on_encrypted_response_iv"
    t.index ["plaid_credential_id"], name: "index_plaid_responses_on_plaid_credential_id"
  end

  create_table "transaction_groups", primary_key: "uuid", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "transactions", id: :string, force: :cascade do |t|
    t.bigint "account_id"
    t.bigint "user_id"
    t.string "payment_channel"
    t.string "description"
    t.float "amount"
    t.datetime "date", precision: nil
    t.boolean "pending"
    t.jsonb "payment_metadata"
    t.jsonb "location_metadata"
    t.string "pending_transaction_id"
    t.string "account_owner"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "split", default: false
    t.uuid "transaction_group_uuid"
    t.string "primary_category"
    t.string "detailed_category"
    t.string "category_confidence"
    t.string "merchant_name"
    t.datetime "deleted_at"
    t.index ["account_id"], name: "index_transactions_on_account_id"
    t.index ["deleted_at"], name: "index_transactions_on_deleted_at"
    t.index ["transaction_group_uuid"], name: "index_transactions_on_transaction_group_uuid"
    t.index ["user_id"], name: "index_transactions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at", precision: nil
    t.datetime "last_sign_in_at", precision: nil
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "plaid_responses", "plaid_credentials"
end
