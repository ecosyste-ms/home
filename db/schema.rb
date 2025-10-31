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

ActiveRecord::Schema[8.1].define(version: 2025_10_31_121500) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "accounts", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.string "collection_method"
    t.datetime "created_at", null: false
    t.integer "days_until_due"
    t.datetime "deleted_at"
    t.string "email", null: false
    t.string "name", null: false
    t.string "payment_method_expiry"
    t.string "payment_method_last4"
    t.string "payment_method_type"
    t.string "profile_picture_url"
    t.boolean "show_profile_picture", default: true
    t.string "status", default: "active"
    t.string "stripe_customer_id"
    t.datetime "suspended_at"
    t.datetime "updated_at", null: false
    t.index ["admin"], name: "index_accounts_on_admin"
    t.index ["deleted_at"], name: "index_accounts_on_deleted_at"
    t.index ["email"], name: "index_accounts_on_email", unique: true
    t.index ["stripe_customer_id"], name: "index_accounts_on_stripe_customer_id", unique: true
  end

  create_table "api_keys", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "apisix_consumer_id"
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.string "key_hash", null: false
    t.string "key_prefix", null: false
    t.datetime "last_used_at"
    t.json "metadata"
    t.string "name", null: false
    t.datetime "revoked_at"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_api_keys_on_account_id"
    t.index ["apisix_consumer_id"], name: "index_api_keys_on_apisix_consumer_id", unique: true
    t.index ["key_hash"], name: "index_api_keys_on_key_hash", unique: true
    t.index ["key_prefix"], name: "index_api_keys_on_key_prefix"
    t.index ["revoked_at"], name: "index_api_keys_on_revoked_at"
  end

  create_table "identities", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "avatar_url"
    t.datetime "created_at", null: false
    t.json "data"
    t.string "email"
    t.string "name"
    t.string "provider", null: false
    t.text "refresh_token"
    t.text "token"
    t.datetime "token_expires_at"
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.string "username"
    t.index ["account_id"], name: "index_identities_on_account_id"
    t.index ["provider", "uid"], name: "index_identities_on_provider_and_uid", unique: true
  end

  create_table "invoices", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.integer "amount_due_cents", default: 0, null: false
    t.integer "amount_paid_cents", default: 0, null: false
    t.datetime "created_at", null: false
    t.string "currency", default: "usd"
    t.json "data"
    t.datetime "due_date"
    t.text "hosted_invoice_url"
    t.text "invoice_pdf_url"
    t.json "metadata"
    t.string "number"
    t.datetime "paid_at"
    t.datetime "period_end"
    t.datetime "period_start"
    t.string "status", null: false
    t.string "stripe_invoice_id"
    t.bigint "subscription_id"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_invoices_on_account_id"
    t.index ["due_date"], name: "index_invoices_on_due_date"
    t.index ["number"], name: "index_invoices_on_number", unique: true
    t.index ["status"], name: "index_invoices_on_status"
    t.index ["stripe_invoice_id"], name: "index_invoices_on_stripe_invoice_id", unique: true
    t.index ["subscription_id"], name: "index_invoices_on_subscription_id"
  end

  create_table "plans", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "billing_period", null: false
    t.datetime "created_at", null: false
    t.string "currency", default: "usd"
    t.datetime "deleted_at"
    t.text "description"
    t.string "display_name"
    t.json "features"
    t.json "metadata"
    t.string "name", null: false
    t.string "plan_family"
    t.integer "position", default: 0
    t.integer "price_cents", default: 0, null: false
    t.boolean "public", default: true, null: false
    t.integer "requests_per_hour", null: false
    t.string "slug", null: false
    t.string "stripe_price_id"
    t.datetime "updated_at", null: false
    t.uuid "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.integer "version", default: 1
    t.boolean "visible", default: true
    t.index ["slug"], name: "index_plans_on_slug", unique: true
    t.index ["stripe_price_id"], name: "index_plans_on_stripe_price_id", unique: true
    t.index ["uuid"], name: "index_plans_on_uuid", unique: true
  end

  create_table "stripe_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.json "data"
    t.text "error_message"
    t.string "event_id", null: false
    t.string "event_type", null: false
    t.datetime "processed_at"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_stripe_events_on_created_at"
    t.index ["event_id"], name: "index_stripe_events_on_event_id", unique: true
    t.index ["event_type"], name: "index_stripe_events_on_event_type"
    t.index ["status"], name: "index_stripe_events_on_status"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.boolean "cancel_at_period_end", default: false
    t.datetime "canceled_at"
    t.datetime "created_at", null: false
    t.datetime "current_period_end"
    t.datetime "current_period_start"
    t.json "data"
    t.integer "discount_amount_cents", default: 0
    t.datetime "ended_at"
    t.json "metadata"
    t.bigint "plan_id", null: false
    t.string "promo_code"
    t.datetime "scheduled_change_date"
    t.bigint "scheduled_plan_id"
    t.string "status", null: false
    t.string "stripe_price_id"
    t.string "stripe_subscription_id"
    t.datetime "trial_end"
    t.datetime "trial_start"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_subscriptions_on_account_id"
    t.index ["current_period_end"], name: "index_subscriptions_on_current_period_end"
    t.index ["plan_id"], name: "index_subscriptions_on_plan_id"
    t.index ["scheduled_plan_id"], name: "index_subscriptions_on_scheduled_plan_id"
    t.index ["status"], name: "index_subscriptions_on_status"
    t.index ["stripe_subscription_id"], name: "index_subscriptions_on_stripe_subscription_id", unique: true
    t.index ["trial_end"], name: "index_subscriptions_on_trial_end"
  end

  add_foreign_key "api_keys", "accounts"
  add_foreign_key "identities", "accounts"
  add_foreign_key "invoices", "accounts"
  add_foreign_key "invoices", "subscriptions"
  add_foreign_key "subscriptions", "accounts"
  add_foreign_key "subscriptions", "plans"
  add_foreign_key "subscriptions", "plans", column: "scheduled_plan_id"
end
