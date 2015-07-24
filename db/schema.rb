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

ActiveRecord::Schema.define(:version => 20150703125720) do

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

  create_table "casse_periodici", :id => false, :force => true do |t|
    t.integer "collocazione_per",               :null => false
    t.integer "catena"
    t.string  "catena_string",    :limit => 8
    t.string  "cassa",            :limit => 8,  :null => false
    t.string  "annata",           :limit => 24
    t.string  "note",             :limit => 64
    t.integer "manifestation_id"
  end

  create_table "centrorete_clavis", :id => false, :force => true do |t|
    t.integer "manifestation_id"
    t.integer "id"
  end

  create_table "collocazioni_musicale", :id => false, :force => true do |t|
    t.integer "d_object_id"
    t.text    "collocation"
    t.text    "folder"
    t.integer "position"
    t.string  "mime_type",   :limit => 96
  end

  add_index "collocazioni_musicale", ["collocation"], :name => "collocazioni_musicale_idx"

  create_table "collocazioni_periodici_civica", :id => false, :force => true do |t|
    t.text    "collocazione"
    t.string  "sequence1",        :limit => 128
    t.integer "manifestation_id"
  end

  create_table "container_items", :force => true do |t|
    t.string  "label",               :limit => 16
    t.integer "row_number"
    t.integer "manifestation_id"
    t.integer "item_id"
    t.integer "consistency_note_id"
    t.integer "library_id"
    t.text    "item_title"
    t.string  "google_doc_key"
    t.integer "created_by"
    t.integer "container_id"
  end

  add_index "container_items", ["item_id"], :name => "container_items_item_id_ndx"

  create_table "containers", :force => true do |t|
    t.string  "label",       :limit => 16,                    :null => false
    t.integer "library_id"
    t.boolean "closed",                    :default => false
    t.integer "created_by"
    t.boolean "prenotabile"
  end

  add_index "containers", ["label"], :name => "containers_label_idx", :unique => true

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

  create_table "da_inserire_in_clavis", :id => false, :force => true do |t|
    t.integer "owner_library_id"
    t.string  "inventory_serie_id", :limit => 128
    t.integer "inventory_number"
    t.text    "collocazione"
    t.text    "titolo"
    t.string  "login",              :limit => 40
    t.date    "date_created"
    t.date    "date_updated"
    t.text    "note"
    t.text    "note_interne"
    t.integer "source_id"
  end

  create_table "da_inserire_in_clavis_copia", :id => false, :force => true do |t|
    t.integer "owner_library_id"
    t.string  "inventory_serie_id", :limit => 128
    t.integer "inventory_number"
    t.text    "collocazione"
    t.text    "titolo"
    t.string  "login",              :limit => 40
    t.date    "date_created"
    t.date    "date_updated"
    t.text    "note"
    t.text    "note_interne"
    t.integer "source_id"
  end

  create_table "da_inserire_in_clavis_temp", :id => false, :force => true do |t|
    t.integer "owner_library_id"
    t.string  "inventory_serie_id", :limit => 128
    t.integer "inventory_number"
    t.text    "collocazione"
    t.text    "titolo"
    t.string  "login",              :limit => 40
    t.date    "date_created"
    t.date    "date_updated"
    t.text    "note"
    t.text    "note_interne"
  end

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

  create_table "kardex_adabas", :force => true do |t|
    t.text    "barcode"
    t.string  "collocazione",  :limit => 160
    t.string  "bid",           :limit => 10
    t.integer "numiniz"
    t.integer "numfine"
    t.string  "datafasc1",     :limit => 10
    t.string  "datafasc2",     :limit => 10
    t.integer "vol"
    t.text    "anno"
    t.string  "tipofasc",      :limit => 1
    t.text    "notefasc"
    t.string  "numalf",        :limit => 15
    t.date    "dataarrivo"
    t.string  "statofasc",     :limit => 2
    t.string  "bib",           :limit => 6
    t.string  "noteesemplare", :limit => 110
  end

  add_index "kardex_adabas", ["bid"], :name => "fascicoli2_bid_idx"

  create_table "musicbrainz_artists_clavis_authorities", :id => false, :force => true do |t|
    t.string  "gid",          :limit => nil
    t.integer "authority_id"
  end

  add_index "musicbrainz_artists_clavis_authorities", ["authority_id"], :name => "musicbrainz_artists_clavis_authorities_authority_id_idx"
  add_index "musicbrainz_artists_clavis_authorities", ["gid"], :name => "musicbrainz_artists_clavis_authorities_gid_idx"

  create_table "open_shelf_items", :id => false, :force => true do |t|
    t.integer "item_id",                  :null => false
    t.integer "created_by"
    t.string  "os_section", :limit => 64
  end

  add_index "open_shelf_items", ["item_id"], :name => "index_open_shelf_items_on_item_id", :unique => true

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

  create_table "ricollocazioni", :id => false, :force => true do |t|
    t.integer "item_id"
    t.integer "class_id"
    t.text    "dewey_collocation"
    t.integer "authority_id"
    t.text    "sort_text"
  end

  add_index "ricollocazioni", ["authority_id"], :name => "ricollocazioni_authority_id_ndx"
  add_index "ricollocazioni", ["class_id"], :name => "ricollocazioni_class_id_ndx"
  add_index "ricollocazioni", ["item_id"], :name => "ricollocazioni_item_id_ndx"
  add_index "ricollocazioni", ["sort_text"], :name => "ricollocazioni_sort_text_ndx"

  create_table "serials_admin_table", :force => true do |t|
    t.integer "anno_fornitura"
    t.text    "titolo"
    t.integer "manifestation_id"
    t.integer "library_id"
    t.integer "numero_fattura"
    t.float   "importo_fattura"
    t.text    "CIG"
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

  create_table "temp_import_erasmo_bibrecords", :id => false, :force => true do |t|
    t.string "id",     :limit => 8,  :null => false
    t.string "leader", :limit => 24
  end

  create_table "temp_import_erasmo_unimarc_tags", :id => false, :force => true do |t|
    t.string "bibrecord_id", :limit => 8, :null => false
    t.string "marctag",      :limit => 3
    t.string "indicator1",   :limit => 1
    t.string "indicator2",   :limit => 1
    t.xml    "subfields"
    t.text   "content"
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

  create_table "temp_subjects", :id => false, :force => true do |t|
    t.text    "s1"
    t.text    "s2"
    t.string  "linktype", :limit => 20
    t.integer "seq"
  end

  create_table "topografico_non_in_clavis", :force => true do |t|
    t.text     "bid"
    t.integer  "id_copia"
    t.integer  "id_titolo"
    t.integer  "owner_library_id"
    t.string   "inventory_serie_id", :limit => 128
    t.integer  "inventory_number"
    t.text     "collocazione"
    t.text     "note"
    t.text     "note_interne"
    t.date     "data_collocazione"
    t.date     "data_aggiornamento"
    t.boolean  "mancante"
    t.text     "titolo"
    t.date     "ctime"
    t.date     "mtime"
    t.string   "login",              :limit => 40
    t.boolean  "deleted",                           :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_by"
    t.integer  "updated_by"
  end

  create_table "users", :force => true do |t|
    t.string   "email",                  :default => "", :null => false
    t.string   "encrypted_password",     :default => "", :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          :default => 0,  :null => false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
    t.string   "google_doc_key"
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

  create_table "xml_import_erasmo", :id => false, :force => true do |t|
    t.integer "id"
    t.xml     "record"
  end

end
