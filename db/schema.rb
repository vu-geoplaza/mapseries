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

ActiveRecord::Schema.define(version: 20181107111603) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "postgis"

  create_table "base_series", id: false, force: :cascade do |t|
    t.string   "name",                null: false
    t.string   "abbr",                null: false
    t.text     "metadata_fields",     null: false
    t.text     "set_metadata_fields", null: false
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.index ["abbr"], name: "index_base_series_on_abbr", unique: true, using: :btree
  end

  create_table "base_sets", force: :cascade do |t|
    t.string   "display_title",                   null: false
    t.string   "editie",           default: "NA"
    t.string   "serie"
    t.string   "titel"
    t.string   "base_series_abbr"
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.index ["base_series_abbr"], name: "index_base_sets_on_base_series_abbr", using: :btree
  end

  create_table "base_sheets", force: :cascade do |t|
    t.string   "title",            null: false
    t.integer  "region_id"
    t.string   "base_series_abbr"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.index ["base_series_abbr"], name: "index_base_sheets_on_base_series_abbr", using: :btree
    t.index ["region_id"], name: "index_base_sheets_on_region_id", using: :btree
  end

  create_table "bibliographic_metadata", id: false, force: :cascade do |t|
    t.string   "oclcnr"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["oclcnr"], name: "index_bibliographic_metadata_on_oclcnr", unique: true, using: :btree
  end

  create_table "copies", force: :cascade do |t|
    t.text     "phys_char"
    t.text     "description"
    t.text     "stamps"
    t.text     "csv_row"
    t.integer  "sheet_id"
    t.integer  "provenance_id"
    t.integer  "shelfmark_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.index ["provenance_id"], name: "index_copies_on_provenance_id", using: :btree
    t.index ["sheet_id"], name: "index_copies_on_sheet_id", using: :btree
    t.index ["shelfmark_id"], name: "index_copies_on_shelfmark_id", using: :btree
  end

  create_table "electronic_versions", force: :cascade do |t|
    t.string   "repository_url"
    t.string   "service_type"
    t.integer  "ogc_web_service_id"
    t.integer  "repository_id"
    t.integer  "copy_id"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
    t.index ["copy_id"], name: "index_electronic_versions_on_copy_id", using: :btree
    t.index ["ogc_web_service_id"], name: "index_electronic_versions_on_ogc_web_service_id", using: :btree
    t.index ["repository_id"], name: "index_electronic_versions_on_repository_id", using: :btree
  end

  create_table "libraries", id: false, force: :cascade do |t|
    t.text     "name"
    t.string   "abbr"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["abbr"], name: "index_libraries_on_abbr", unique: true, using: :btree
  end

  create_table "libraries_users", id: false, force: :cascade do |t|
    t.string  "library_abbr"
    t.integer "user_id"
    t.index ["user_id", "library_abbr"], name: "by_users_and_libraries", unique: true, using: :btree
    t.index ["user_id"], name: "index_libraries_users_on_user_id", using: :btree
  end

  create_table "ogc_web_services", force: :cascade do |t|
    t.string   "url"
    t.string   "services"
    t.string   "viewer_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "provenances", force: :cascade do |t|
    t.string   "name"
    t.text     "description"
    t.string   "library_abbr"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.index ["library_abbr"], name: "index_provenances_on_library_abbr", using: :btree
  end

  create_table "regions", force: :cascade do |t|
    t.string   "name",                                                   null: false
    t.text     "polygon"
    t.geometry "geom",       limit: {:srid=>28992, :type=>"st_polygon"}
    t.datetime "created_at",                                             null: false
    t.datetime "updated_at",                                             null: false
  end

  create_table "repositories", force: :cascade do |t|
    t.string   "name"
    t.string   "base_url"
    t.text     "description"
    t.string   "library_abbr"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.index ["library_abbr"], name: "index_repositories_on_library_abbr", using: :btree
  end

  create_table "sheets", force: :cascade do |t|
    t.date     "pubdate"
    t.boolean  "pubdate_exact",    default: true
    t.string   "edition",          default: "NA"
    t.integer  "is_based_on"
    t.integer  "base_sheet_id"
    t.integer  "base_set_id"
    t.string   "titel"
    t.string   "display_title"
    t.string   "nummer"
    t.string   "uitgever"
    t.string   "verkend"
    t.string   "herzien"
    t.string   "bewerkt"
    t.string   "uitgave"
    t.string   "bijgewerkt"
    t.string   "opname_jaar"
    t.string   "basis_jaar"
    t.string   "basis"
    t.string   "schaal"
    t.string   "bewerker"
    t.string   "reproductie"
    t.string   "editie"
    t.boolean  "waterstaatskaart"
    t.boolean  "bijkaart_we"
    t.boolean  "bijkaart_hw"
    t.text     "opmerkingen"
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.index ["base_set_id"], name: "index_sheets_on_base_set_id", using: :btree
    t.index ["base_sheet_id"], name: "index_sheets_on_base_sheet_id", using: :btree
  end

  create_table "shelfmarks", force: :cascade do |t|
    t.string   "shelfmark"
    t.string   "library_abbr"
    t.string   "oclcnr"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.index ["library_abbr"], name: "index_shelfmarks_on_library_abbr", using: :btree
    t.index ["oclcnr"], name: "index_shelfmarks_on_oclcnr", using: :btree
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.integer  "role"
    t.index ["email"], name: "index_users_on_email", unique: true, using: :btree
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  end

  add_foreign_key "base_sets", "base_series", column: "base_series_abbr", primary_key: "abbr"
  add_foreign_key "base_sheets", "base_series", column: "base_series_abbr", primary_key: "abbr"
  add_foreign_key "base_sheets", "regions"
  add_foreign_key "copies", "provenances"
  add_foreign_key "copies", "sheets"
  add_foreign_key "copies", "shelfmarks"
  add_foreign_key "electronic_versions", "copies"
  add_foreign_key "electronic_versions", "ogc_web_services"
  add_foreign_key "electronic_versions", "repositories"
  add_foreign_key "libraries_users", "libraries", column: "library_abbr", primary_key: "abbr"
  add_foreign_key "libraries_users", "users"
  add_foreign_key "provenances", "libraries", column: "library_abbr", primary_key: "abbr"
  add_foreign_key "repositories", "libraries", column: "library_abbr", primary_key: "abbr"
  add_foreign_key "sheets", "base_sets"
  add_foreign_key "sheets", "base_sheets"
  add_foreign_key "shelfmarks", "bibliographic_metadata", column: "oclcnr", primary_key: "oclcnr"
  add_foreign_key "shelfmarks", "libraries", column: "library_abbr", primary_key: "abbr"
end
