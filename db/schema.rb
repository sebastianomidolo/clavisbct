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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130424094029) do

  create_table "d_objects", :force => true do |t|
    t.string   "drive",     :limit => 48
    t.string   "container", :limit => 240
    t.string   "filepath",  :limit => 320
    t.xml      "tags"
    t.decimal  "bfilesize",                :precision => 15, :scale => 0
    t.string   "mime_type", :limit => 24
    t.datetime "f_ctime"
    t.datetime "f_mtime"
  end

  create_table "file_infos", :force => true do |t|
    t.string  "collocazione", :limit => 128
    t.string  "filepath",     :limit => 320
    t.string  "drive",        :limit => 48
    t.xml     "mp3_tags"
    t.integer "tracknum"
    t.string  "container",    :limit => 240
    t.decimal "bfilesize",                   :precision => 15, :scale => 0
    t.string  "mime_type",    :limit => 24
  end

  create_table "procultura_import", :id => false, :force => true do |t|
    t.integer "theid"
    t.string  "theimagepath", :limit => nil, :null => false
    t.string  "thetype",      :limit => nil
    t.string  "theauthor",    :limit => nil
    t.string  "thesubject",   :limit => nil
    t.string  "thetitle",     :limit => nil
    t.string  "thespec",      :limit => nil
    t.string  "thedrawer",    :limit => nil
  end

  create_table "subject_subject", :id => false, :force => true do |t|
    t.integer "s1_id",                  :null => false
    t.integer "s2_id",                  :null => false
    t.string  "linktype", :limit => 24, :null => false
  end

  create_table "subjects", :force => true do |t|
    t.text "heading", :null => false
  end

  add_index "subjects", ["heading"], :name => "subjects_heading_idx"

  create_table "temp_subjects", :id => false, :force => true do |t|
    t.text   "s1"
    t.text   "s2"
    t.string "linktype", :limit => 20
  end

  create_table "users", :force => true do |t|
    t.string   "email",                  :default => "", :null => false
    t.string   "login",                  :default => "", :null => false
    t.string   "encrypted_password",     :default => "", :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string   "password_salt"
    t.integer  "sign_in_count",          :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

end
