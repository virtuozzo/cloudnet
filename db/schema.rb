# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20170222201912) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.string   "gateway_id",            limit: 255
    t.date     "invoice_start"
    t.integer  "invoice_day"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.integer  "risky_cards_remaining",             default: 3
    t.string   "vat_number",            limit: 255
    t.integer  "coupon_id"
    t.datetime "coupon_activated_at"
    t.boolean  "maxmind_exempt",                    default: false
    t.integer  "payg_balance",                      default: 0
    t.string   "address1"
    t.string   "address2"
    t.string   "country"
    t.string   "postal"
    t.string   "address3"
    t.string   "address4"
    t.string   "company_name"
    t.boolean  "auto_topup",                        default: true
    t.boolean  "whitelisted",                       default: false
  end

  add_index "accounts", ["coupon_id"], name: "index_accounts_on_coupon_id", using: :btree
  add_index "accounts", ["user_id"], name: "index_accounts_on_user_id", using: :btree

  create_table "active_admin_comments", force: :cascade do |t|
    t.string   "namespace",     limit: 255
    t.text     "body"
    t.string   "resource_id",   limit: 255, null: false
    t.string   "resource_type", limit: 255, null: false
    t.integer  "author_id"
    t.string   "author_type",   limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "active_admin_comments", ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id", using: :btree
  add_index "active_admin_comments", ["namespace"], name: "index_active_admin_comments_on_namespace", using: :btree
  add_index "active_admin_comments", ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id", using: :btree

  create_table "activities", force: :cascade do |t|
    t.integer  "trackable_id"
    t.string   "trackable_type", limit: 255
    t.integer  "owner_id"
    t.string   "owner_type",     limit: 255
    t.string   "key",            limit: 255
    t.text     "parameters"
    t.integer  "recipient_id"
    t.string   "recipient_type", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "activities", ["owner_id", "owner_type"], name: "index_activities_on_owner_id_and_owner_type", using: :btree
  add_index "activities", ["recipient_id", "recipient_type"], name: "index_activities_on_recipient_id_and_recipient_type", using: :btree
  add_index "activities", ["trackable_id", "trackable_type"], name: "index_activities_on_trackable_id_and_trackable_type", using: :btree

  create_table "addons", force: :cascade do |t|
    t.string   "name"
    t.text     "description"
    t.decimal  "price",           default: 0.0
    t.string   "task"
    t.boolean  "hidden",          default: false
    t.boolean  "request_support", default: false
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
  end

  create_table "api_keys", force: :cascade do |t|
    t.string   "title",                        null: false
    t.string   "encrypted_key",                null: false
    t.integer  "user_id"
    t.boolean  "active",        default: true, null: false
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.datetime "deleted_at"
  end

  add_index "api_keys", ["encrypted_key"], name: "index_api_keys_on_encrypted_key", unique: true, using: :btree
  add_index "api_keys", ["user_id"], name: "index_api_keys_on_user_id", using: :btree

  create_table "billing_cards", force: :cascade do |t|
    t.string   "bin",             limit: 255
    t.string   "ip_address",      limit: 255
    t.string   "city",            limit: 255
    t.string   "region",          limit: 255
    t.string   "postal",          limit: 255
    t.string   "country",         limit: 255
    t.text     "fraud_body"
    t.string   "processor_token", limit: 255
    t.integer  "account_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "expiry_month",    limit: 255
    t.string   "expiry_year",     limit: 255
    t.string   "cardholder",      limit: 255
    t.string   "user_agent",      limit: 255
    t.decimal  "fraud_score"
    t.boolean  "fraud_verified",              default: false
    t.string   "last4",           limit: 255
    t.string   "card_type",       limit: 255
    t.datetime "deleted_at"
    t.string   "address1",        limit: 255
    t.string   "address2",        limit: 255
    t.boolean  "primary",                     default: false
    t.boolean  "fraud_safe",                  default: false
  end

  create_table "build_checker_data", force: :cascade do |t|
    t.integer  "template_id",                  null: false
    t.integer  "location_id",                  null: false
    t.datetime "start_after"
    t.datetime "build_start"
    t.datetime "build_end"
    t.integer  "build_result",     default: 0, null: false
    t.boolean  "scheduled"
    t.integer  "state",            default: 0, null: false
    t.datetime "delete_queued_at"
    t.datetime "deleted_at"
    t.string   "onapp_identifier"
    t.datetime "notified_at"
    t.string   "error"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.integer  "failed_in_build",  default: 0
  end

  add_index "build_checker_data", ["build_result"], name: "index_build_checker_data_on_build_result", using: :btree
  add_index "build_checker_data", ["deleted_at"], name: "index_build_checker_data_on_deleted_at", using: :btree
  add_index "build_checker_data", ["location_id"], name: "index_build_checker_data_on_location_id", using: :btree
  add_index "build_checker_data", ["scheduled", "start_after"], name: "index_build_checker_data_on_scheduled_and_start_after", where: "(scheduled IS TRUE)", using: :btree
  add_index "build_checker_data", ["scheduled"], name: "index_build_checker_data_on_scheduled", where: "(scheduled IS TRUE)", using: :btree
  add_index "build_checker_data", ["state"], name: "index_build_checker_data_on_state", using: :btree
  add_index "build_checker_data", ["template_id", "scheduled"], name: "index_build_checker_data_on_template_id_and_scheduled", unique: true, using: :btree
  add_index "build_checker_data", ["template_id"], name: "index_build_checker_data_on_template_id", using: :btree

  create_table "certificates", force: :cascade do |t|
    t.string   "name"
    t.text     "description"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.integer  "avatar"
  end

  create_table "certificates_locations", force: :cascade do |t|
    t.integer "certificate_id"
    t.integer "location_id"
  end

  add_index "certificates_locations", ["certificate_id", "location_id"], name: "index_certificates_locations_on_certificate_id_and_location_id", using: :btree

  create_table "charges", force: :cascade do |t|
    t.integer  "invoice_id"
    t.string   "source_type", limit: 255
    t.integer  "source_id"
    t.integer  "amount",      limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "reference",   limit: 255
  end

  add_index "charges", ["invoice_id"], name: "index_charges_on_invoice_id", using: :btree

  create_table "coupons", force: :cascade do |t|
    t.string   "coupon_code",     limit: 255
    t.boolean  "active",                      default: true
    t.integer  "percentage",                  default: 20
    t.integer  "duration_months",             default: 3
    t.datetime "created_at"
    t.datetime "updated_at"
    t.date     "expiry_date"
  end

  add_index "coupons", ["coupon_code"], name: "index_coupons_on_coupon_code", unique: true, using: :btree

  create_table "credit_note_items", force: :cascade do |t|
    t.string   "description",    limit: 255
    t.integer  "units"
    t.integer  "unit_cost",      limit: 8
    t.integer  "hours"
    t.integer  "net_cost",       limit: 8
    t.integer  "tax_cost",       limit: 8
    t.datetime "deleted_at"
    t.integer  "credit_note_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "metadata"
    t.integer  "source_id"
    t.string   "source_type",    limit: 255
  end

  add_index "credit_note_items", ["credit_note_id"], name: "index_credit_note_items_on_credit_note_id", using: :btree

  create_table "credit_notes", force: :cascade do |t|
    t.integer  "account_id"
    t.string   "vat_number",      limit: 255
    t.boolean  "vat_exempt"
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "remaining_cost",  limit: 8
    t.integer  "sequential_id"
    t.string   "state",           limit: 255
    t.string   "tax_code",        limit: 255
    t.text     "billing_address"
    t.integer  "coupon_id"
  end

  add_index "credit_notes", ["account_id"], name: "index_credit_notes_on_account_id", using: :btree

  create_table "data_migrations", force: :cascade do |t|
    t.string "version"
  end

  create_table "dns_zones", force: :cascade do |t|
    t.string   "domain",     limit: 255
    t.integer  "domain_id"
    t.integer  "user_id"
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "dns_zones", ["domain_id"], name: "index_dns_zones_on_domain_id", using: :btree

  create_table "email_whitelists", force: :cascade do |t|
    t.string   "email",      limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "indices", force: :cascade do |t|
    t.integer  "index_cpu",       default: 0
    t.integer  "index_iops",      default: 0
    t.integer  "index_bandwidth", default: 0
    t.integer  "location_id"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end

  add_index "indices", ["created_at", "location_id"], name: "index_indices_on_created_at_and_location_id", using: :btree
  add_index "indices", ["location_id"], name: "index_indices_on_location_id", using: :btree

  create_table "invoice_items", force: :cascade do |t|
    t.string   "description", limit: 255
    t.integer  "invoice_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.integer  "net_cost",    limit: 8
    t.integer  "tax_cost",    limit: 8
    t.text     "metadata"
    t.integer  "source_id"
    t.string   "source_type", limit: 255
  end

  add_index "invoice_items", ["invoice_id"], name: "index_invoice_items_on_invoice_id", using: :btree

  create_table "invoices", force: :cascade do |t|
    t.integer  "account_id"
    t.string   "vat_number",          limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.boolean  "vat_exempt"
    t.integer  "sequential_id"
    t.string   "state",               limit: 255, default: "unpaid"
    t.string   "tax_code",            limit: 255
    t.text     "billing_address"
    t.integer  "coupon_id"
    t.string   "invoice_type",        limit: 255
    t.boolean  "transactions_capped"
  end

  add_index "invoices", ["account_id"], name: "index_invoices_on_account_id", using: :btree

  create_table "keys", force: :cascade do |t|
    t.string   "title"
    t.text     "key"
    t.integer  "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
  end

  add_index "keys", ["user_id"], name: "index_keys_on_user_id", using: :btree

  create_table "locations", force: :cascade do |t|
    t.string   "latitude",            limit: 255
    t.string   "longitude",           limit: 255
    t.string   "provider",            limit: 255
    t.string   "country",             limit: 255
    t.string   "city",                limit: 255
    t.integer  "memory"
    t.integer  "disk_size"
    t.integer  "cpu"
    t.integer  "hv_group_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "hidden",                          default: true
    t.decimal  "price_memory",                    default: 0.0
    t.decimal  "price_disk",                      default: 0.0
    t.decimal  "price_cpu",                       default: 0.0
    t.decimal  "price_bw",                        default: 0.0
    t.string   "provider_link",       limit: 255
    t.integer  "network_limit"
    t.string   "photo_ids",           limit: 255
    t.decimal  "price_ip_address",                default: 0.0
    t.boolean  "budget_vps",                      default: false
    t.integer  "inclusive_bandwidth",             default: 100
    t.boolean  "ssd_disks",                       default: false
    t.datetime "deleted_at"
    t.integer  "max_index_cpu",                   default: 0
    t.integer  "max_index_iops",                  default: 0
    t.integer  "max_index_bandwidth",             default: 0
    t.float    "max_index_uptime",                default: 0.0
    t.integer  "region_id"
    t.text     "summary"
    t.integer  "pingdom_id"
    t.string   "pingdom_name"
    t.string   "hv_group_version"
  end

  add_index "locations", ["country"], name: "index_locations_on_country", using: :btree
  add_index "locations", ["hv_group_id"], name: "index_locations_on_hv_group_id", using: :btree
  add_index "locations", ["region_id"], name: "index_locations_on_region_id", using: :btree

  create_table "packages", force: :cascade do |t|
    t.integer  "location_id"
    t.integer  "memory"
    t.integer  "cpus"
    t.integer  "disk_size"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "ip_addresses", default: 1
  end

  add_index "packages", ["location_id"], name: "index_packages_on_location_id", using: :btree

  create_table "payment_receipts", force: :cascade do |t|
    t.integer  "account_id"
    t.integer  "remaining_cost",  limit: 8
    t.integer  "net_cost",        limit: 8
    t.string   "reference",       limit: 255
    t.text     "metadata"
    t.integer  "sequential_id"
    t.string   "state",           limit: 255
    t.text     "billing_address"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "pay_source",      limit: 255
    t.datetime "deleted_at"
  end

  create_table "regions", force: :cascade do |t|
    t.string   "name"
    t.text     "description"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "risky_cards", force: :cascade do |t|
    t.string   "fingerprint"
    t.integer  "account_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.datetime "deleted_at"
  end

  add_index "risky_cards", ["account_id"], name: "index_risky_cards_on_account_id", using: :btree

  create_table "risky_ip_addresses", force: :cascade do |t|
    t.string   "ip_address"
    t.integer  "account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
  end

  add_index "risky_ip_addresses", ["account_id"], name: "index_risky_ip_addresses_on_account_id", using: :btree

  create_table "server_addons", force: :cascade do |t|
    t.integer  "addon_id"
    t.integer  "server_id"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.datetime "notified_at"
    t.datetime "processed_at"
    t.datetime "deleted_at"
  end

  add_index "server_addons", ["addon_id"], name: "index_server_addons_on_addon_id", using: :btree
  add_index "server_addons", ["server_id"], name: "index_server_addons_on_server_id", using: :btree

  create_table "server_backups", force: :cascade do |t|
    t.boolean  "built",                       default: false
    t.datetime "built_at"
    t.datetime "backup_created"
    t.string   "identifier",      limit: 255
    t.boolean  "locked"
    t.integer  "disk_id"
    t.integer  "min_disk_size"
    t.integer  "min_memory_size"
    t.integer  "backup_id"
    t.integer  "server_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.integer  "backup_size"
  end

  add_index "server_backups", ["identifier"], name: "index_server_backups_on_identifier", using: :btree

  create_table "server_events", force: :cascade do |t|
    t.integer  "reference"
    t.datetime "transaction_created"
    t.string   "action",              limit: 255
    t.string   "status",              limit: 255
    t.integer  "server_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "transaction_updated"
  end

  add_index "server_events", ["reference"], name: "index_server_events_on_reference", using: :btree

  create_table "server_hourly_transactions", force: :cascade do |t|
    t.integer  "server_id"
    t.integer  "net_cost"
    t.text     "metadata"
    t.integer  "coupon_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.integer  "account_id"
    t.boolean  "duplicate",  default: false
  end

  add_index "server_hourly_transactions", ["account_id"], name: "index_server_hourly_transactions_on_account_id", using: :btree
  add_index "server_hourly_transactions", ["coupon_id"], name: "index_server_hourly_transactions_on_coupon_id", using: :btree
  add_index "server_hourly_transactions", ["server_id"], name: "index_server_hourly_transactions_on_server_id", using: :btree

  create_table "server_ip_addresses", force: :cascade do |t|
    t.string   "address"
    t.string   "netmask"
    t.string   "network"
    t.string   "broadcast"
    t.string   "gateway"
    t.integer  "server_id"
    t.string   "identifier"
    t.boolean  "primary",    default: false
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.datetime "deleted_at"
  end

  add_index "server_ip_addresses", ["address"], name: "index_server_ip_addresses_on_address", using: :btree
  add_index "server_ip_addresses", ["identifier"], name: "index_server_ip_addresses_on_identifier", using: :btree
  add_index "server_ip_addresses", ["server_id"], name: "index_server_ip_addresses_on_server_id", using: :btree

  create_table "server_usages", force: :cascade do |t|
    t.integer  "server_id"
    t.text     "usages"
    t.string   "usage_type", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  add_index "server_usages", ["server_id"], name: "index_server_usages_on_server_id", using: :btree

  create_table "server_wizards", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "location_id"
    t.string   "location_name", limit: 255
    t.integer  "os_distro_id"
    t.integer  "template_id"
    t.integer  "memory"
    t.integer  "cpus"
    t.integer  "disk_size"
    t.integer  "bandwidth"
    t.integer  "card_id"
    t.string   "name",          limit: 255
    t.string   "hostname",      limit: 255
  end

  create_table "servers", force: :cascade do |t|
    t.string   "identifier",               limit: 255
    t.string   "name",                     limit: 255
    t.string   "hostname",                 limit: 255
    t.string   "state",                    limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "built",                                default: false
    t.boolean  "locked",                               default: true
    t.boolean  "suspended",                            default: true
    t.integer  "cpus"
    t.integer  "hypervisor_id"
    t.string   "root_password",            limit: 255
    t.integer  "memory"
    t.string   "os",                       limit: 255
    t.string   "os_distro",                limit: 255
    t.string   "remote_access_password",   limit: 255
    t.integer  "disk_size"
    t.integer  "user_id"
    t.decimal  "bandwidth",                            default: 0.0
    t.integer  "location_id"
    t.integer  "template_id"
    t.datetime "deleted_at"
    t.string   "delete_ip_address",        limit: 255
    t.boolean  "in_beta",                              default: false
    t.integer  "ip_addresses",                         default: 1
    t.boolean  "payg",                                 default: false
    t.string   "payment_type",             limit: 255, default: "prepaid"
    t.time     "state_changed_at"
    t.boolean  "stuck",                                default: false
    t.decimal  "forecasted_rev",                       default: 0.0
    t.string   "provisioner_role"
    t.boolean  "no_refresh",                           default: false
    t.integer  "free_billing_bandwidth",               default: 0
    t.integer  "validation_reason",                    default: 0
    t.integer  "exceed_bw_user_notif",                 default: 0
    t.integer  "exceed_bw_value",                      default: 0
    t.datetime "exceed_bw_user_last_sent"
    t.integer  "exceed_bw_admin_notif",                default: 0
    t.datetime "provisioned_at"
    t.string   "provisioner_job_id"
    t.datetime "fault_reported_at"
  end

  add_index "servers", ["deleted_at"], name: "index_servers_on_deleted_at", using: :btree
  add_index "servers", ["identifier"], name: "index_servers_on_identifier", using: :btree
  add_index "servers", ["location_id"], name: "index_servers_on_location_id", using: :btree
  add_index "servers", ["template_id"], name: "index_servers_on_template_id", using: :btree
  add_index "servers", ["user_id"], name: "index_servers_on_user_id", using: :btree

  create_table "sessions", force: :cascade do |t|
    t.string   "session_id", limit: 255, null: false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], name: "index_sessions_on_session_id", unique: true, using: :btree
  add_index "sessions", ["updated_at"], name: "index_sessions_on_updated_at", using: :btree

  create_table "systems", force: :cascade do |t|
    t.string   "key",        null: false
    t.string   "value",      null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "systems", ["key"], name: "index_systems_on_key", unique: true, using: :btree

  create_table "taggings", force: :cascade do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "taggings", ["tag_id", "taggable_id", "taggable_type"], name: "index_taggings_on_tag_id_and_taggable_id_and_taggable_type", unique: true, using: :btree

  create_table "tags", force: :cascade do |t|
    t.string   "label"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "tags", ["label"], name: "index_tags_on_label", unique: true, using: :btree

  create_table "templates", force: :cascade do |t|
    t.string   "os_type",         limit: 255
    t.string   "onapp_os_distro", limit: 255
    t.string   "identifier",      limit: 255
    t.integer  "hourly_cost",                 default: 1
    t.string   "name",            limit: 255
    t.integer  "location_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "min_memory",                  default: 0
    t.integer  "min_disk",                    default: 0
    t.boolean  "hidden",                      default: false
    t.string   "os_distro",       limit: 255
    t.boolean  "build_checker",               default: false, null: false
  end

  add_index "templates", ["build_checker", "location_id"], name: "index_templates_on_build_checker_and_location_id", where: "(build_checker IS TRUE)", using: :btree
  add_index "templates", ["identifier"], name: "index_templates_on_identifier", using: :btree
  add_index "templates", ["location_id"], name: "index_templates_on_location_id", using: :btree

  create_table "ticket_replies", force: :cascade do |t|
    t.text     "body"
    t.integer  "ticket_id"
    t.string   "sender",     limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "reference",  limit: 255
    t.integer  "user_id"
  end

  add_index "ticket_replies", ["reference"], name: "index_ticket_replies_on_reference", using: :btree
  add_index "ticket_replies", ["ticket_id"], name: "index_ticket_replies_on_ticket_id", using: :btree
  add_index "ticket_replies", ["user_id"], name: "index_ticket_replies_on_user_id", using: :btree

  create_table "tickets", force: :cascade do |t|
    t.string   "subject",    limit: 255
    t.text     "body"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "reference",  limit: 255
    t.string   "status",     limit: 255
    t.string   "department", limit: 255
    t.integer  "server_id",              default: -1
  end

  add_index "tickets", ["reference"], name: "index_tickets_on_reference", using: :btree
  add_index "tickets", ["server_id"], name: "index_tickets_on_server_id", using: :btree
  add_index "tickets", ["user_id"], name: "index_tickets_on_user_id", using: :btree

  create_table "uptimes", force: :cascade do |t|
    t.integer  "avgresponse"
    t.integer  "downtime"
    t.datetime "starttime"
    t.integer  "unmonitored"
    t.integer  "uptime"
    t.integer  "location_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "uptimes", ["location_id"], name: "index_uptimes_on_location_id", using: :btree
  add_index "uptimes", ["starttime"], name: "index_uptimes_on_starttime", using: :btree

  create_table "user_server_counts", force: :cascade do |t|
    t.integer  "user_id"
    t.date     "date"
    t.integer  "servers_count"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  add_index "user_server_counts", ["user_id", "date"], name: "count_for_user_at_day", unique: true, using: :btree
  add_index "user_server_counts", ["user_id"], name: "index_user_server_counts_on_user_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email",                    limit: 255, default: "",        null: false
    t.string   "encrypted_password",       limit: 255, default: "",        null: false
    t.string   "reset_password_token",     limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                        default: 0,         null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",       limit: 255
    t.string   "last_sign_in_ip",          limit: 255
    t.string   "confirmation_token",       limit: 255
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email",        limit: 255
    t.integer  "failed_attempts",                      default: 0,         null: false
    t.string   "unlock_token",             limit: 255
    t.datetime "locked_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "full_name",                limit: 255
    t.boolean  "admin",                                default: false
    t.string   "status",                   limit: 255, default: "pending"
    t.string   "onapp_user",               limit: 255
    t.string   "onapp_email",              limit: 255
    t.string   "encrypted_onapp_password", limit: 255
    t.integer  "vm_max",                               default: 6
    t.integer  "memory_max",                           default: 8192
    t.integer  "cpu_max",                              default: 4
    t.integer  "storage_max",                          default: 120
    t.integer  "bandwidth_max",                        default: 1024
    t.datetime "deleted_at"
    t.boolean  "suspended",                            default: false
    t.integer  "account_id"
    t.string   "otp_auth_secret",          limit: 255
    t.string   "otp_recovery_secret",      limit: 255
    t.boolean  "otp_enabled",                          default: false,     null: false
    t.boolean  "otp_mandatory",                        default: false,     null: false
    t.datetime "otp_enabled_on"
    t.integer  "otp_time_drift",                       default: 0,         null: false
    t.integer  "otp_failed_attempts",                  default: 0,         null: false
    t.integer  "otp_recovery_counter",                 default: 0,         null: false
    t.string   "otp_persistence_seed",     limit: 255
    t.string   "otp_session_challenge",    limit: 255
    t.datetime "otp_challenge_expires"
    t.string   "onapp_id"
    t.integer  "notif_before_shutdown",                default: 3
    t.integer  "notif_before_destroy",                 default: 21
    t.integer  "notif_delivered",                      default: 0
    t.datetime "last_notif_email_sent"
    t.integer  "admin_destroy_request",                default: 0
    t.string   "vm_count_tag"
    t.string   "vm_count_trend"
    t.string   "phone_number"
    t.datetime "phone_verified_at"
    t.boolean  "api_enabled",                          default: true
  end

  add_index "users", ["account_id"], name: "index_users_on_account_id", using: :btree
  add_index "users", ["deleted_at"], name: "index_users_on_deleted_at", using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["onapp_user"], name: "index_users_on_onapp_user", using: :btree
  add_index "users", ["otp_challenge_expires"], name: "index_users_on_otp_challenge_expires", using: :btree
  add_index "users", ["otp_session_challenge"], name: "index_users_on_otp_session_challenge", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

  add_foreign_key "api_keys", "users"
  add_foreign_key "build_checker_data", "locations"
  add_foreign_key "build_checker_data", "templates"
  add_foreign_key "indices", "locations"
  add_foreign_key "keys", "users"
  add_foreign_key "locations", "regions"
  add_foreign_key "server_addons", "addons"
  add_foreign_key "server_addons", "servers"
  add_foreign_key "server_ip_addresses", "servers"
  add_foreign_key "uptimes", "locations"
  add_foreign_key "user_server_counts", "users"
end
