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

ActiveRecord::Schema[8.1].define(version: 2026_09_21_150818) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "activity_notes", force: :cascade do |t|
    t.string "author"
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.bigint "notable_id", null: false
    t.string "notable_type", null: false
    t.boolean "pinned", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["notable_type", "notable_id"], name: "index_activity_notes_on_notable"
  end

  create_table "customers", force: :cascade do |t|
    t.string "address_line_1"
    t.string "address_line_2"
    t.string "city"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.text "notes"
    t.string "phone", null: false
    t.string "postal_code"
    t.string "province"
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
  end

  create_table "documents", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "document_type"
    t.bigint "documentable_id", null: false
    t.string "documentable_type", null: false
    t.string "label"
    t.datetime "updated_at", null: false
    t.string "uploaded_by"
    t.index ["documentable_type", "documentable_id"], name: "index_documents_on_documentable"
  end

  create_table "jobs", force: :cascade do |t|
    t.string "address_line_1"
    t.string "address_line_2"
    t.string "assigned_to"
    t.string "city"
    t.datetime "created_at", null: false
    t.bigint "customer_id", null: false
    t.text "description"
    t.date "end_date"
    t.decimal "estimated_value", precision: 10, scale: 2
    t.integer "job_type", default: 0
    t.bigint "lead_id"
    t.string "postal_code"
    t.string "province"
    t.date "start_date"
    t.integer "status", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_jobs_on_customer_id"
    t.index ["lead_id"], name: "index_jobs_on_lead_id"
  end

  create_table "leads", force: :cascade do |t|
    t.string "assigned_to"
    t.datetime "created_at", null: false
    t.bigint "customer_id", null: false
    t.text "description"
    t.decimal "estimated_value", precision: 10, scale: 2
    t.date "follow_up_date"
    t.integer "job_type", default: 0
    t.integer "source", default: 0
    t.integer "status", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_leads_on_customer_id"
  end

  create_table "line_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description", null: false
    t.integer "item_type", null: false
    t.bigint "order_id", null: false
    t.decimal "quantity", precision: 10, scale: 2, default: "1.0"
    t.decimal "total", precision: 10, scale: 2, default: "0.0"
    t.string "unit"
    t.decimal "unit_price", precision: 10, scale: 2, default: "0.0"
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_line_items_on_order_id"
  end

  create_table "orders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "customer_id", null: false
    t.date "due_date"
    t.date "issued_date"
    t.bigint "job_id", null: false
    t.bigint "lead_id"
    t.text "notes"
    t.string "order_number"
    t.integer "status", default: 0, null: false
    t.decimal "subtotal", precision: 10, scale: 2, default: "0.0"
    t.decimal "tax_rate", precision: 5, scale: 4, default: "0.0"
    t.decimal "total", precision: 10, scale: 2, default: "0.0"
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_orders_on_customer_id"
    t.index ["job_id"], name: "index_orders_on_job_id"
    t.index ["lead_id"], name: "index_orders_on_lead_id"
    t.index ["order_number"], name: "index_orders_on_order_number", unique: true
  end

  create_table "quote_line_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description", null: false
    t.integer "item_type", null: false
    t.decimal "quantity", precision: 10, scale: 2, default: "1.0"
    t.bigint "quote_id", null: false
    t.decimal "total", precision: 10, scale: 2, default: "0.0"
    t.string "unit"
    t.decimal "unit_price", precision: 10, scale: 2, default: "0.0"
    t.datetime "updated_at", null: false
    t.index ["quote_id"], name: "index_quote_line_items_on_quote_id"
  end

  create_table "quotes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "customer_id", null: false
    t.date "issued_date"
    t.bigint "lead_id", null: false
    t.text "notes"
    t.string "quote_number"
    t.integer "status", default: 0, null: false
    t.decimal "subtotal", precision: 10, scale: 2, default: "0.0"
    t.decimal "tax_rate", precision: 5, scale: 4, default: "0.0"
    t.decimal "total", precision: 10, scale: 2, default: "0.0"
    t.datetime "updated_at", null: false
    t.date "valid_until"
    t.index ["customer_id"], name: "index_quotes_on_customer_id"
    t.index ["lead_id"], name: "index_quotes_on_lead_id"
    t.index ["quote_number"], name: "index_quotes_on_quote_number", unique: true
  end

  create_table "rooms", force: :cascade do |t|
    t.decimal "area", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.decimal "length", precision: 8, scale: 2, null: false
    t.string "name", null: false
    t.string "notes"
    t.bigint "quote_id", null: false
    t.datetime "updated_at", null: false
    t.decimal "width", precision: 8, scale: 2, null: false
    t.index ["quote_id"], name: "index_rooms_on_quote_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "jobs", "customers"
  add_foreign_key "jobs", "leads"
  add_foreign_key "leads", "customers"
  add_foreign_key "line_items", "orders"
  add_foreign_key "orders", "customers"
  add_foreign_key "orders", "jobs"
  add_foreign_key "orders", "leads"
  add_foreign_key "quote_line_items", "quotes"
  add_foreign_key "quotes", "customers"
  add_foreign_key "quotes", "leads"
  add_foreign_key "rooms", "quotes"
end
