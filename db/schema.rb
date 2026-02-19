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

ActiveRecord::Schema[7.2].define(version: 2026_02_19_162027) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "device_tokens", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "token", null: false
    t.string "platform", default: "ios", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "token"], name: "index_device_tokens_on_user_id_and_token", unique: true
    t.index ["user_id"], name: "index_device_tokens_on_user_id"
  end

  create_table "maintenance_request_notes", force: :cascade do |t|
    t.bigint "maintenance_request_id", null: false
    t.bigint "user_id", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["maintenance_request_id"], name: "index_maintenance_request_notes_on_maintenance_request_id"
    t.index ["user_id"], name: "index_maintenance_request_notes_on_user_id"
  end

  create_table "maintenance_requests", force: :cascade do |t|
    t.string "issue_type"
    t.string "location"
    t.integer "severity", default: 0
    t.integer "status", default: 0
    t.text "conversation_summary"
    t.boolean "allows_direct_contact"
    t.bigint "tenant_id", null: false
    t.bigint "assigned_vendor_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "chat_history", default: []
    t.index ["assigned_vendor_id"], name: "index_maintenance_requests_on_assigned_vendor_id"
    t.index ["tenant_id"], name: "index_maintenance_requests_on_tenant_id"
  end

  create_table "manager_invitations", force: :cascade do |t|
    t.bigint "created_by_id"
    t.bigint "claimed_by_id"
    t.string "manager_name"
    t.string "manager_email"
    t.string "code"
    t.datetime "expires_at"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["claimed_by_id"], name: "index_manager_invitations_on_claimed_by_id"
    t.index ["code"], name: "index_manager_invitations_on_code", unique: true
    t.index ["created_by_id"], name: "index_manager_invitations_on_created_by_id"
  end

  create_table "phone_verifications", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "phone_number"
    t.string "code"
    t.datetime "verified_at"
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_phone_verifications_on_user_id"
  end

  create_table "properties", force: :cascade do |t|
    t.string "address", null: false
    t.string "name"
    t.integer "property_type", default: 0, null: false
    t.bigint "property_manager_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["property_manager_id"], name: "index_properties_on_property_manager_id"
  end

  create_table "property_manager_vendors", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "vendor_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_active", default: true, null: false
    t.index ["user_id", "vendor_id"], name: "index_property_manager_vendors_on_user_id_and_vendor_id", unique: true
    t.index ["user_id"], name: "index_property_manager_vendors_on_user_id"
    t.index ["vendor_id"], name: "index_property_manager_vendors_on_vendor_id"
  end

  create_table "quote_requests", force: :cascade do |t|
    t.bigint "maintenance_request_id", null: false
    t.bigint "vendor_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "token", default: -> { "gen_random_uuid()" }, null: false
    t.index ["maintenance_request_id", "vendor_id"], name: "index_quote_requests_on_maintenance_request_id_and_vendor_id", unique: true
    t.index ["maintenance_request_id"], name: "index_quote_requests_on_maintenance_request_id"
    t.index ["token"], name: "index_quote_requests_on_token", unique: true
    t.index ["vendor_id"], name: "index_quote_requests_on_vendor_id"
  end

  create_table "quotes", force: :cascade do |t|
    t.bigint "vendor_id", null: false
    t.bigint "maintenance_request_id", null: false
    t.decimal "estimated_cost"
    t.datetime "estimated_arrival_time"
    t.text "work_description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["maintenance_request_id"], name: "index_quotes_on_maintenance_request_id"
    t.index ["vendor_id"], name: "index_quotes_on_vendor_id"
  end

  create_table "tenant_invitations", force: :cascade do |t|
    t.bigint "unit_id", null: false
    t.bigint "created_by_id", null: false
    t.string "code", null: false
    t.string "tenant_name", null: false
    t.string "tenant_email", null: false
    t.bigint "claimed_by_id"
    t.datetime "expires_at", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["claimed_by_id"], name: "index_tenant_invitations_on_claimed_by_id"
    t.index ["code"], name: "index_tenant_invitations_on_code", unique: true
    t.index ["created_by_id"], name: "index_tenant_invitations_on_created_by_id"
    t.index ["unit_id"], name: "index_tenant_invitations_on_unit_id"
  end

  create_table "units", force: :cascade do |t|
    t.bigint "property_id", null: false
    t.string "identifier"
    t.integer "floor"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["property_id"], name: "index_units_on_property_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "name", null: false
    t.string "phone"
    t.string "address"
    t.integer "role", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "provider"
    t.string "uid"
    t.string "password_reset_token"
    t.datetime "password_reset_sent_at"
    t.bigint "unit_id"
    t.string "mobile_phone"
    t.string "home_phone"
    t.boolean "phone_verified", default: false, null: false
    t.date "move_in_date"
    t.date "move_out_date"
    t.boolean "active", default: true, null: false
    t.boolean "google_auth_enabled", default: false, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["password_reset_token"], name: "index_users_on_password_reset_token", unique: true
    t.index ["unit_id"], name: "index_users_on_unit_id"
  end

  create_table "vendor_ratings", force: :cascade do |t|
    t.bigint "vendor_id", null: false
    t.bigint "maintenance_request_id", null: false
    t.bigint "tenant_id", null: false
    t.integer "stars", null: false
    t.text "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["maintenance_request_id"], name: "index_vendor_ratings_on_maintenance_request_id"
    t.index ["tenant_id"], name: "index_vendor_ratings_on_tenant_id"
    t.index ["vendor_id", "maintenance_request_id"], name: "index_vendor_ratings_on_vendor_id_and_maintenance_request_id", unique: true
    t.index ["vendor_id"], name: "index_vendor_ratings_on_vendor_id"
  end

  create_table "vendors", force: :cascade do |t|
    t.string "name"
    t.string "phone_number"
    t.decimal "rating"
    t.boolean "is_available"
    t.string "location"
    t.integer "vendor_type"
    t.text "specialties"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "contact_name"
    t.string "cell_phone"
    t.string "email"
    t.string "address"
    t.string "website"
    t.text "notes"
    t.bigint "owner_user_id"
    t.index ["owner_user_id"], name: "index_vendors_on_owner_user_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "device_tokens", "users"
  add_foreign_key "maintenance_request_notes", "maintenance_requests"
  add_foreign_key "maintenance_request_notes", "users"
  add_foreign_key "maintenance_requests", "users", column: "tenant_id"
  add_foreign_key "maintenance_requests", "vendors", column: "assigned_vendor_id"
  add_foreign_key "phone_verifications", "users"
  add_foreign_key "properties", "users", column: "property_manager_id"
  add_foreign_key "property_manager_vendors", "users"
  add_foreign_key "property_manager_vendors", "vendors"
  add_foreign_key "quote_requests", "maintenance_requests"
  add_foreign_key "quote_requests", "vendors"
  add_foreign_key "quotes", "maintenance_requests"
  add_foreign_key "quotes", "vendors"
  add_foreign_key "tenant_invitations", "units"
  add_foreign_key "tenant_invitations", "users", column: "claimed_by_id"
  add_foreign_key "tenant_invitations", "users", column: "created_by_id"
  add_foreign_key "units", "properties"
  add_foreign_key "users", "units"
  add_foreign_key "vendor_ratings", "maintenance_requests"
  add_foreign_key "vendor_ratings", "users", column: "tenant_id"
  add_foreign_key "vendor_ratings", "vendors"
  add_foreign_key "vendors", "users", column: "owner_user_id"
end
