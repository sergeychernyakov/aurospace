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

ActiveRecord::Schema[7.2].define(version: 2026_04_07_200000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "balance_cents", default: 0, null: false
    t.string "currency", default: "RUB", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "discarded_at"
    t.index ["discarded_at"], name: "index_accounts_on_discarded_at"
    t.index ["user_id"], name: "index_accounts_on_user_id", unique: true
  end

  create_table "ledger_entries", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "order_id", null: false
    t.integer "entry_type", null: false
    t.integer "amount_cents", null: false
    t.string "currency", default: "RUB", null: false
    t.string "reference"
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_ledger_entries_on_account_id"
    t.index ["order_id"], name: "index_ledger_entries_on_order_id"
  end

  create_table "notification_logs", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.string "mail_type", null: false
    t.string "recipient", null: false
    t.datetime "sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "discarded_at"
    t.index ["discarded_at"], name: "index_notification_logs_on_discarded_at"
    t.index ["order_id", "mail_type"], name: "index_notification_logs_on_order_id_and_mail_type", unique: true
  end

  create_table "orders", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "amount_cents", null: false
    t.string "currency", default: "RUB", null: false
    t.integer "status", default: 0, null: false
    t.string "payment_provider"
    t.string "external_payment_id"
    t.datetime "paid_at"
    t.datetime "cancelled_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "discarded_at"
    t.index ["discarded_at"], name: "index_orders_on_discarded_at"
    t.index ["status"], name: "index_orders_on_status"
    t.index ["user_id"], name: "index_orders_on_user_id"
    t.check_constraint "amount_cents > 0", name: "orders_amount_cents_positive"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "discarded_at"
    t.index ["discarded_at"], name: "index_users_on_discarded_at"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "webhook_events", force: :cascade do |t|
    t.string "provider", null: false
    t.string "external_event_id", null: false
    t.string "event_type", null: false
    t.jsonb "payload", default: {}
    t.datetime "processed_at"
    t.string "status", default: "pending", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "discarded_at"
    t.index ["discarded_at"], name: "index_webhook_events_on_discarded_at"
    t.index ["external_event_id"], name: "index_webhook_events_on_external_event_id", unique: true
    t.index ["provider"], name: "index_webhook_events_on_provider"
  end

  add_foreign_key "accounts", "users"
  add_foreign_key "ledger_entries", "accounts"
  add_foreign_key "ledger_entries", "orders"
  add_foreign_key "notification_logs", "orders"
  add_foreign_key "orders", "users"
end
