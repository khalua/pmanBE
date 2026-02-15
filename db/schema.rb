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

ActiveRecord::Schema[7.2].define(version: 2026_02_15_063736) do
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
    t.index ["assigned_vendor_id"], name: "index_maintenance_requests_on_assigned_vendor_id"
    t.index ["tenant_id"], name: "index_maintenance_requests_on_tenant_id"
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
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["password_reset_token"], name: "index_users_on_password_reset_token", unique: true
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
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "maintenance_requests", "users", column: "tenant_id"
  add_foreign_key "maintenance_requests", "vendors", column: "assigned_vendor_id"
  add_foreign_key "quotes", "maintenance_requests"
  add_foreign_key "quotes", "vendors"
end
