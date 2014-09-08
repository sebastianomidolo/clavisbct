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

ActiveRecord::Schema.define(:version => 20140725095516) do

  create_table "access_rights", :id => false, :force => true do |t|
    t.integer "code",        :limit => 2,  :null => false
    t.string  "label",       :limit => 32, :null => false
    t.string  "description"
  end

  add_index "access_rights", ["label"], :name => "access_rights_label_idx", :unique => true

  create_table "archivio_periodici", :id => false, :force => true do |t|
    t.text    "title"
    t.string  "bid",              :limit => 10
    t.integer "manifestation_id"
    t.integer "library_id"
    t.string  "provider",         :limit => 12
  end

  create_table "attachment_categories", :id => false, :force => true do |t|
    t.string "code",        :limit => 1,  :null => false
    t.string "label",       :limit => 32, :null => false
    t.string "description"
  end

  create_table "attachments", :id => false, :force => true do |t|
    t.integer "d_object_id",                           :null => false
    t.integer "attachable_id",                         :null => false
    t.integer "position"
    t.string  "attachable_type",        :limit => 24,  :null => false
    t.string  "attachment_category_id", :limit => 1
    t.string  "folder",                 :limit => 512
  end

  create_table "av_manifestations", :id => false, :force => true do |t|
    t.integer "idvolume"
    t.integer "manifestation_id"
  end

  add_index "av_manifestations", ["idvolume", "manifestation_id"], :name => "av_manifestation_idx", :unique => true
  add_index "av_manifestations", ["idvolume"], :name => "av_manifestation_idvolume_idx"
  add_index "av_manifestations", ["manifestation_id"], :name => "av_manifestation_manifestation_id_idx"

  create_table "avdata", :id => false, :force => true do |t|
    t.integer "primary_id"
    t.integer "manifestation_id"
    t.integer "bm_id"
  end

  create_table "biblioteche_celdes", :id => false, :force => true do |t|
    t.text    "label"
    t.integer "library_id"
  end

  create_table "collocazioni_musicale", :id => false, :force => true do |t|
    t.integer "d_object_id"
    t.text    "collocation"
    t.text    "folder"
    t.integer "position"
    t.string  "mime_type",   :limit => 96
  end

  add_index "collocazioni_musicale", ["collocation"], :name => "collocazioni_musicale_idx"

  create_table "d_objects", :force => true do |t|
    t.string   "filename",        :limit => 2048
    t.xml      "tags"
    t.decimal  "bfilesize",                       :precision => 15, :scale => 0
    t.string   "mime_type",       :limit => 96
    t.datetime "f_ctime"
    t.datetime "f_mtime"
    t.datetime "f_atime"
    t.integer  "access_right_id", :limit => 2
  end

  add_index "d_objects", ["access_right_id"], :name => "access_right_id_idx"
  add_index "d_objects", ["filename"], :name => "d_objects_filename_idx", :unique => true

  create_table "dng_sessions", :force => true do |t|
    t.string   "client_ip",  :limit => 128
    t.datetime "login_time"
    t.integer  "patron_id",                 :null => false
  end

  create_table "excel_files", :force => true do |t|
    t.string   "file_name"
    t.integer  "file_size"
    t.datetime "updated_at"
  end

  create_table "excel_sheets", :force => true do |t|
    t.string  "sheet_name"
    t.integer "sheet_number",                 :null => false
    t.integer "excel_file_id",                :null => false
    t.text    "columns"
    t.string  "tablename",     :limit => 256
  end

  add_index "excel_sheets", ["sheet_number", "excel_file_id"], :name => "excel_sheets_idx1", :unique => true
  add_index "excel_sheets", ["tablename"], :name => "index_excel_sheets_on_tablename", :unique => true

  create_table "import_bctaudio_metatags", :id => false, :force => true do |t|
    t.string  "collocation", :limit => 128
    t.string  "folder",      :limit => 512
    t.string  "filename",    :limit => 2048
    t.integer "tracknum"
    t.xml     "tags"
  end

  add_index "import_bctaudio_metatags", ["filename"], :name => "import_bctaudio_metatags_filename_idx"

  create_table "import_libroparlato_colloc", :id => false, :force => true do |t|
    t.string  "collocation", :limit => 128
    t.integer "d_object_id"
    t.integer "position"
  end

  add_index "import_libroparlato_colloc", ["collocation"], :name => "import_libroparlato_colloc_collocation_idx"

  create_table "musicbrainz_artists_clavis_authorities", :id => false, :force => true do |t|
    t.string  "gid",          :limit => nil
    t.integer "authority_id"
  end

  add_index "musicbrainz_artists_clavis_authorities", ["authority_id"], :name => "musicbrainz_artists_clavis_authorities_authority_id_idx"
  add_index "musicbrainz_artists_clavis_authorities", ["gid"], :name => "musicbrainz_artists_clavis_authorities_gid_idx"

  create_table "ordini_periodici_musicale", :id => false, :force => true do |t|
    t.text    "title"
    t.integer "manifestation_id"
    t.integer "excel_cell_id"
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

  create_table "serials_admin_table", :force => true do |t|
    t.text    "titolo"
    t.integer "manifestation_id"
    t.integer "library_id"
    t.integer "numero_fattura"
    t.float   "importo_fattura"
    t.string  "fattura_o_nota_di_credito", :limit => 1
    t.date    "data_emissione"
    t.date    "data_pagamento"
    t.text    "prezzo"
    t.text    "commissione_sconto"
    t.text    "totale"
    t.text    "iva"
    t.text    "prezzo_finale"
    t.integer "numcopie"
    t.integer "ordnum"
    t.integer "ordanno"
    t.integer "ordprogressivo"
    t.text    "periodo"
    t.text    "stato"
    t.text    "formato"
    t.text    "note_interne"
  end

  create_table "subject_subject", :id => false, :force => true do |t|
    t.integer "s1_id",                  :null => false
    t.integer "s2_id",                  :null => false
    t.string  "linktype", :limit => 24, :null => false
    t.integer "seq"
    t.string  "linknote"
  end

  add_index "subject_subject", ["linktype", "s1_id", "s2_id"], :name => "index_subject_subject_on_linktype_and_s1_id_and_s2_id"

  create_table "subjects", :force => true do |t|
    t.text    "heading",                                               :null => false
    t.integer "clavis_authority_id"
    t.string  "clavis_subject_class", :limit => 32
    t.boolean "inbct",                              :default => false
    t.text    "scope_note"
  end

  add_index "subjects", ["clavis_authority_id"], :name => "index_subjects_on_clavis_authority_id"
  add_index "subjects", ["clavis_subject_class"], :name => "index_subjects_on_clavis_subject_class"
  add_index "subjects", ["heading"], :name => "index_subjects_on_heading"

  create_table "temp_crossref", :id => false, :force => true do |t|
    t.integer "source_id"
    t.text    "heading"
    t.string  "linknote"
    t.text    "target"
    t.string  "linktype",  :limit => 24
    t.integer "target_id"
    t.integer "linked_id"
  end

  create_table "temp_goethe_import", :id => false, :force => true do |t|
    t.xml "xmlrec"
  end

  create_table "temp_intestazioni_mancanti", :id => false, :force => true do |t|
    t.text "heading"
  end

  create_table "temp_links", :id => false, :force => true do |t|
    t.integer "source_id"
    t.integer "target_id"
    t.integer "linked_id"
    t.string  "linktype",  :limit => 20
    t.text    "s1"
    t.text    "s2"
    t.text    "heading"
    t.text    "linknote"
    t.integer "seq"
  end

  create_table "temp_links_bt", :id => false, :force => true do |t|
    t.string  "linktype", :limit => 20
    t.text    "s1"
    t.text    "s2"
    t.text    "heading"
    t.text    "linknote"
    t.integer "seq"
  end

  create_table "temp_subjects", :id => false, :force => true do |t|
    t.text    "s1"
    t.text    "s2"
    t.string  "linktype", :limit => 20
    t.integer "seq"
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
