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

ActiveRecord::Schema[8.1].define(version: 2026_05_24_205613) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "customers", force: :cascade do |t|
    t.string "address"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.string "phone", null: false
    t.datetime "updated_at", null: false
  end

  create_table "jobs", force: :cascade do |t|
    t.string "assigned_to"
    t.datetime "created_at", null: false
    t.bigint "customer_id"
    t.text "description"
    t.decimal "estimated_value"
    t.integer "job_type", default: 0
    t.bigint "lead_id"
    t.string "source"
    t.integer "status", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_jobs_on_customer_id"
    t.index ["lead_id"], name: "index_jobs_on_lead_id"
  end

  create_table "leads", force: :cascade do |t|
    t.string "assigned_to"
    t.datetime "created_at", null: false
    t.bigint "customer_id"
    t.text "description"
    t.decimal "estimated_value", precision: 10, scale: 2
    t.integer "job_type", default: 0
    t.integer "source", default: 0
    t.integer "status", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_leads_on_customer_id"
  end

  add_foreign_key "jobs", "customers"
  add_foreign_key "jobs", "leads"
  add_foreign_key "leads", "customers"
end
