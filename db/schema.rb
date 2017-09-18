# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20000101000001) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "groups", force: :cascade do |t|
    t.string "name", null: false
    t.string "tags", array: true
    t.string "slack_channel"
    t.boolean "default", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "rewards", force: :cascade do |t|
    t.string "name", null: false
    t.string "image_url"
    t.integer "cost", null: false
    t.integer "stock_count"
    t.boolean "visible", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "transactions", force: :cascade do |t|
    t.bigint "sender_id"
    t.bigint "recipient_id"
    t.integer "amount"
    t.string "message"
    t.string "tags", array: true
    t.integer "transaction_type", default: 0, null: false
    t.bigint "reward_id"
    t.bigint "group_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id"], name: "index_transactions_on_group_id"
    t.index ["recipient_id"], name: "index_transactions_on_recipient_id"
    t.index ["reward_id"], name: "index_transactions_on_reward_id"
    t.index ["sender_id"], name: "index_transactions_on_sender_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "username", null: false
    t.string "display_name"
    t.string "email"
    t.string "external_id"
    t.integer "allowance", default: 0, null: false
    t.integer "balance", default: 0, null: false
    t.string "avatar_url"
    t.string "avatar_hash"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["external_id"], name: "index_users_on_external_id"
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "transactions", "users", column: "recipient_id"
  add_foreign_key "transactions", "users", column: "sender_id"
end
