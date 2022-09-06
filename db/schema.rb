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

ActiveRecord::Schema.define(:version => 20210518164047) do

  create_table "access_rights", :id => false, :force => true do |t|
    t.integer "code",        :limit => 2,  :null => false
    t.string  "label",       :limit => 32, :null => false
    t.string  "description"
  end

  add_index "access_rights", ["label"], :name => "access_rights_label_idx", :unique => true

  create_table "adabas_2011_registro_inventari", :force => true do |t|
    t.string  "bid",                  :limit => 10
    t.string  "biblio",               :limit => 6
    t.string  "serie",                :limit => 3
    t.integer "inv"
    t.string  "collocazione",         :limit => 160
    t.text    "isbd"
    t.text    "note"
    t.string  "data_inserimento",     :limit => 10
    t.string  "schedone",             :limit => 75
    t.text    "val_euro"
    t.text    "valore"
    t.string  "d_ser_prec",           :limit => 10
    t.string  "segn_prec",            :limit => 82
    t.string  "sezione_acq",          :limit => 12
    t.date    "data_ord"
    t.integer "num_ord"
    t.integer "prezzo_totale_lire"
    t.string  "codforn",              :limit => 9
    t.string  "stato_ord",            :limit => 2
    t.string  "note_ord",             :limit => 75
    t.string  "note_forn",            :limit => 75
    t.string  "tipo_acquisto",        :limit => 2
    t.decimal "prezzo_previsto_euro",                :precision => 10, :scale => 2
    t.integer "library_id"
    t.integer "supplier_id"
  end

  add_index "adabas_2011_registro_inventari", ["biblio"], :name => "registro_inventari_biblio_idx"
  add_index "adabas_2011_registro_inventari", ["bid"], :name => "registro_inventari_bid_idx"
  add_index "adabas_2011_registro_inventari", ["inv"], :name => "adabas_2011_registro_inventari_inv_ndx"
  add_index "adabas_2011_registro_inventari", ["serie"], :name => "registro_inventari_serie_idx"

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

  create_table "attesa_a_banco_prestiti", :id => false, :force => true do |t|
    t.integer "id"
    t.integer "loan_id"
    t.integer "wait_minutes"
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

  create_table "barcodes_doppi", :id => false, :force => true do |t|
    t.string  "barcode",     :limit => 64
    t.string  "item_status", :limit => 1
    t.integer "count",       :limit => 8
  end

  create_table "bib_sections", :force => true do |t|
    t.string "name", :limit => 32
  end

  add_index "bib_sections", ["name"], :name => "bib_sections_name_idx", :unique => true

  create_table "biblioteche_celdes", :id => false, :force => true do |t|
    t.text    "label"
    t.integer "library_id"
  end

  create_table "bio_icon_namespaces", :id => false, :force => true do |t|
    t.string "label", :limit => 8,   :null => false
    t.string "title", :limit => 32
    t.string "descr", :limit => 128
  end

  create_table "bio_icon_namespaces_users", :id => false, :force => true do |t|
    t.string  "label",   :null => false
    t.integer "user_id", :null => false
  end

  add_index "bio_icon_namespaces_users", ["label", "user_id"], :name => "bio_icon_namespaces_users_idx", :unique => true

  create_table "bio_iconografico_topics", :force => true do |t|
    t.xml "tags"
  end

  create_table "bioiconografico", :id => false, :force => true do |t|
    t.integer "id"
    t.integer "seqnum"
    t.string  "intestazione",         :limit => 1240
    t.string  "luogo_nascita",        :limit => 80
    t.string  "data_nascita",         :limit => 80
    t.string  "data_nascita_stringa", :limit => 9
    t.string  "luogo_morte",          :limit => 80
    t.string  "data_morte",           :limit => 80
    t.string  "data_morte_stringa",   :limit => 9
    t.text    "luoghi_di_soggiorno"
    t.string  "esistenza_in_vita",    :limit => 80
    t.text    "qualificazioni"
    t.string  "var1",                 :limit => 220
    t.string  "var2",                 :limit => 180
    t.string  "var3",                 :limit => 80
    t.string  "var4",                 :limit => 180
    t.string  "var5",                 :limit => 80
    t.text    "luoghi_visitati"
    t.string  "link_scheda",          :limit => 180
    t.text    "note"
    t.string  "altri_link",           :limit => 1240
    t.string  "sigla_operatore",      :limit => 60
    t.integer "num_scatola"
  end

  create_table "bioiconografico_images", :id => false, :force => true do |t|
    t.integer "id"
    t.string  "filename", :limit => 240
  end

  create_table "bncf_terms", :id => false, :force => true do |t|
    t.integer "id",                        :null => false
    t.integer "bncf_id"
    t.string  "category",   :limit => 21
    t.string  "term",       :limit => 128
    t.string  "rdftype",    :limit => 24
    t.integer "parent_id"
    t.text    "definition"
    t.string  "termtype",   :limit => 12
  end

  add_index "bncf_terms", ["id"], :name => "bncf_terms_id_ndx", :unique => true
  add_index "bncf_terms", ["term"], :name => "bncf_terms_term_ndx"

  create_table "centrorete_clavis", :id => false, :force => true do |t|
    t.integer "manifestation_id"
    t.integer "id"
  end

  create_table "closed_stack_item_requests", :force => true do |t|
    t.integer  "item_id",                           :null => false
    t.integer  "patron_id",                         :null => false
    t.integer  "dng_session_id",                    :null => false
    t.boolean  "printed",        :default => false, :null => false
    t.datetime "request_time"
    t.integer  "daily_counter"
    t.integer  "created_by"
    t.boolean  "archived",       :default => false, :null => false
    t.datetime "confirm_time"
    t.datetime "print_time"
    t.integer  "confirmed_by"
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

  create_table "comuni_italiani", :id => false, :force => true do |t|
    t.string "codnaz",        :limit => 4
    t.string "provincia",     :limit => 5
    t.string "denominazione", :limit => 62
    t.string "varcodnaz",     :limit => 4
    t.string "varcodcat",     :limit => 4
    t.string "varprov",       :limit => 5
    t.string "vardenom",      :limit => 62
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
  add_index "container_items", ["label"], :name => "container_items_idx"

  create_table "containers", :force => true do |t|
    t.string  "label",       :limit => 16,                    :null => false
    t.integer "library_id"
    t.boolean "closed",                    :default => false
    t.integer "created_by"
    t.boolean "prenotabile"
  end

  add_index "containers", ["label"], :name => "containers_label_idx", :unique => true

  create_table "d_objects", :force => true do |t|
    t.string   "filename_old_style",  :limit => 2048
    t.xml      "tags"
    t.decimal  "bfilesize",                           :precision => 15, :scale => 0
    t.string   "mime_type",           :limit => 96
    t.datetime "f_ctime"
    t.datetime "f_mtime"
    t.datetime "f_atime"
    t.integer  "access_right_id",     :limit => 2
    t.string   "type",                :limit => 32
    t.integer  "d_objects_folder_id",                                                :null => false
    t.string   "name",                :limit => 512
  end

  add_index "d_objects", ["access_right_id"], :name => "access_right_id_idx"
  add_index "d_objects", ["d_objects_folder_id"], :name => "d_objects_folders_id_idx"
  add_index "d_objects", ["filename_old_style"], :name => "d_objects_filename_idx", :unique => true
  add_index "d_objects", ["name"], :name => "d_objects_name_idx"
  add_index "d_objects", ["type"], :name => "index_d_objects_on_type"

  create_table "d_objects_folders", :force => true do |t|
    t.text    "name",            :null => false
    t.xml     "tags"
    t.integer "access_right_id"
  end

  add_index "d_objects_folders", ["name"], :name => "d_objects_folders_idx_name", :unique => true

  create_table "d_objects_folders_users", :id => false, :force => true do |t|
    t.integer "d_objects_folder_id"
    t.integer "user_id",                            :null => false
    t.string  "pattern",             :limit => 128
    t.string  "mode",                :limit => 2,   :null => false
  end

  add_index "d_objects_folders_users", ["d_objects_folder_id", "user_id"], :name => "d_objects_folders_users_idx", :unique => true
  add_index "d_objects_folders_users", ["pattern", "user_id"], :name => "d_objects_folders_users_pattern_idx", :unique => true

  create_table "da_inserire_in_clavis", :id => false, :force => true do |t|
    t.integer "home_library_id"
    t.string  "inventory_serie_id", :limit => 128
    t.integer "inventory_number"
    t.text    "collocazione"
    t.text    "titolo"
    t.string  "login",              :limit => 40
    t.date    "date_created"
    t.date    "date_updated"
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

  create_table "daily_counters", :force => true do |t|
  end

  create_table "dng_sessions", :force => true do |t|
    t.string   "client_ip",  :limit => 128
    t.datetime "login_time"
    t.integer  "patron_id",                 :null => false
  end

  add_index "dng_sessions", ["patron_id"], :name => "dng_sessions_patron_idx"

  create_table "email_verificate", :id => false, :force => true do |t|
    t.string "email", :limit => 128
    t.string "stato", :limit => 24
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

  create_table "excolloc", :id => false, :force => true do |t|
    t.integer "item_id"
    t.text    "excollocazione"
  end

  create_table "identity_cards", :force => true do |t|
    t.string  "name"
    t.string  "lastname"
    t.string  "national_id",  :limit => 64
    t.date    "birth_date"
    t.string  "birth_city"
    t.string  "unique_id",    :limit => 32
    t.boolean "doc_uploaded",                :default => false
    t.string  "client_ip",    :limit => 128
    t.string  "email"
  end

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

  create_table "iscritti_newsletter", :id => false, :force => true do |t|
    t.text "email"
  end

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

  create_table "le_ricollocazioni", :id => false, :force => true do |t|
    t.integer "item_id"
    t.integer "class_id"
    t.text    "dewey_collocation"
    t.text    "vedetta"
    t.integer "authority_id"
    t.text    "sort_text"
  end

  add_index "le_ricollocazioni", ["authority_id"], :name => "le_ricollocazioni_authority_id_ndx"
  add_index "le_ricollocazioni", ["class_id"], :name => "le_ricollocazioni_class_id_ndx"
  add_index "le_ricollocazioni", ["item_id"], :name => "le_ricollocazioni_item_id_ndx"
  add_index "le_ricollocazioni", ["sort_text"], :name => "le_ricollocazioni_sort_text_ndx"

  create_table "manifestations_d_objects", :id => false, :force => true do |t|
    t.integer "d_object_id"
    t.integer "manifestation_id"
  end

  create_table "manifestations_d_objects_folders", :id => false, :force => true do |t|
    t.integer "d_object_folder_id"
    t.integer "manifestation_id"
  end

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

  create_table "patrons_stats", :id => false, :force => true do |t|
    t.string  "gender",                    :limit => 1
    t.string  "citizenship",               :limit => 64
    t.string  "Anni utilizzo MyDiscovery", :limit => nil
    t.float   "Anno di nascita"
    t.integer "Numero di accessi"
    t.integer "opac_prenotazioni"
    t.integer "opac_rinnovi"
    t.integer "num_prestiti_totali"
    t.integer "num_prestiti_annullati"
    t.integer "num_richieste_a_magazzino"
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

  create_table "rfid_summary", :id => false, :force => true do |t|
    t.integer "library_id",    :null => false
    t.date    "snapshot_date", :null => false
    t.integer "tagged_count",  :null => false
  end

  create_table "ricollocazioni", :id => false, :force => true do |t|
    t.integer "item_id"
    t.integer "class_id"
    t.text    "dewey_collocation"
    t.text    "vedetta"
    t.integer "authority_id"
    t.text    "sort_text"
  end

  add_index "ricollocazioni", ["authority_id"], :name => "ricollocazioni_authority_id_ndx"
  add_index "ricollocazioni", ["class_id"], :name => "ricollocazioni_class_id_ndx"
  add_index "ricollocazioni", ["item_id"], :name => "ricollocazioni_item_id_ndx"
  add_index "ricollocazioni", ["sort_text"], :name => "ricollocazioni_sort_text_ndx"

  create_table "roles", :force => true do |t|
    t.string "name", :null => false
  end

  add_index "roles", ["name"], :name => "roles_names_idx", :unique => true

  create_table "roles_users", :id => false, :force => true do |t|
    t.integer "role_id"
    t.integer "user_id"
  end

  add_index "roles_users", ["role_id", "user_id"], :name => "roles_users_idx", :unique => true

  create_table "salsano_clavis", :id => false, :force => true do |t|
    t.string  "ISBNISSN",         :limit => 32
    t.string  "EAN",              :limit => 32
    t.text    "NumeroISBN"
    t.text    "AltroISBN"
    t.integer "salsano_id"
    t.integer "manifestation_id"
  end

  create_table "schema_collocazioni_centrale", :force => true do |t|
    t.string  "piano",          :limit => 24
    t.string  "scaffale",       :limit => 24
    t.string  "palchetto",      :limit => 24
    t.string  "filtro_colloc",  :limit => 36
    t.integer "bib_section_id",                                   :null => false
    t.string  "notes",          :limit => 128
    t.boolean "locked",                        :default => false
  end

  create_table "sequenza_numeri", :id => false, :force => true do |t|
    t.integer "id"
  end

  create_table "serial_invoices", :id => false, :force => true do |t|
    t.integer "clavis_invoice_id",                                :null => false
    t.decimal "total_amount",      :precision => 19, :scale => 2
    t.integer "serial_list_id",                                   :null => false
  end

  create_table "serial_libraries", :id => false, :force => true do |t|
    t.integer  "serial_list_id",                  :null => false
    t.integer  "clavis_library_id",               :null => false
    t.string   "sigla",             :limit => 1
    t.integer  "updated_by"
    t.datetime "date_updated"
    t.string   "nickname",          :limit => 64
  end

  add_index "serial_libraries", ["serial_list_id", "clavis_library_id"], :name => "serial_libraries_ndx", :unique => true

  create_table "serial_lists", :force => true do |t|
    t.string  "title",          :limit => 128,                    :null => false
    t.string  "year",           :limit => 4
    t.string  "note"
    t.boolean "locked",                        :default => false
    t.string  "import_file",    :limit => 128
    t.string  "libraries_file", :limit => 128
    t.boolean "is_public",                     :default => false
    t.boolean "onelib",                        :default => false
  end

  add_index "serial_lists", ["title"], :name => "serial_lists_ndx", :unique => true

  create_table "serial_subscriptions", :id => false, :force => true do |t|
    t.integer  "serial_title_id",                                                              :null => false
    t.integer  "library_id",                                                                   :null => false
    t.string   "note"
    t.integer  "numero_copie",                                                  :default => 1, :null => false
    t.integer  "updated_by"
    t.datetime "date_updated"
    t.string   "tipo_fornitura",    :limit => 1,                                               :null => false
    t.decimal  "prezzo",                         :precision => 19, :scale => 2
    t.integer  "serial_invoice_id"
  end

  create_table "serial_titles", :force => true do |t|
    t.integer  "serial_list_id",                                                     :null => false
    t.integer  "manifestation_id"
    t.string   "title"
    t.string   "sortkey"
    t.decimal  "prezzo_stimato",   :precision => 19, :scale => 2
    t.boolean  "sospeso",                                         :default => false
    t.boolean  "estero"
    t.text     "note"
    t.integer  "updated_by"
    t.datetime "date_updated"
    t.text     "textdata"
    t.text     "note_fornitore"
  end

  add_index "serial_titles", ["title", "serial_list_id"], :name => "serial_titles_ndx", :unique => true

  create_table "serial_users", :id => false, :force => true do |t|
    t.integer "serial_list_id"
    t.integer "user_id"
  end

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

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "shelf_sonia", :id => false, :force => true do |t|
    t.integer  "shelf_id"
    t.integer  "object_id"
    t.string   "object_class", :limit => 32
    t.string   "item_status",  :limit => 1
    t.datetime "date_created"
    t.datetime "date_updated"
    t.integer  "created_by"
    t.integer  "modified_by"
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

  create_table "target_lettura", :id => false, :force => true do |t|
    t.integer "manifestation_id"
    t.text    "target"
  end

  create_table "temp_analisi_collocazioni", :id => false, :force => true do |t|
    t.text    "primo_elemento_collocazione"
    t.integer "numero esemplari",            :limit => 8
  end

  create_table "temp_analisi_collocazioni_secondo_elemento", :id => false, :force => true do |t|
    t.text    "secondo_elemento_collocazione"
    t.integer "numero esemplari",              :limit => 8
  end

  create_table "temp_collocazioni_ai_piani", :id => false, :force => true do |t|
    t.string "collocazione", :limit => 24
    t.string "dove",         :limit => 36
  end

  create_table "temp_d_objects_manifestation_id", :id => false, :force => true do |t|
    t.integer "id"
    t.string  "manifestation_id", :limit => nil
  end

  create_table "temp_import_areaonlus", :id => false, :force => true do |t|
    t.text    "oid"
    t.text    "isbn"
    t.text    "data_caricamento"
    t.string  "bid",              :limit => 10
    t.integer "manifestation_id"
    t.string  "sbam_oid",         :limit => 12
  end

  create_table "temp_import_librinlinea", :id => false, :force => true do |t|
    t.text   "isbn"
    t.string "bid",  :limit => 10
  end

  add_index "temp_import_librinlinea", ["bid"], :name => "temp_import_librinlinea_idx", :unique => true

  create_table "temp_import_sbam", :id => false, :force => true do |t|
    t.text "oid"
    t.text "isbn"
    t.text "bid"
  end

  add_index "temp_import_sbam", ["bid"], :name => "temp_import_sbam_idx", :unique => true

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

  create_table "temp_mlol_consultazioni", :id => false, :force => true do |t|
    t.string  "barcode",         :limit => 24
    t.date    "data_iscrizione"
    t.integer "consultazioni"
    t.integer "prestiti"
    t.integer "patron_id"
  end

  create_table "temp_mlol_fasce_eta", :id => false, :force => true do |t|
    t.integer "year_from"
    t.integer "year_to"
  end

  create_table "temp_mlol_iscritti", :id => false, :force => true do |t|
    t.integer "id_mlol"
    t.string  "barcode",                     :limit => 24
    t.date    "data_iscrizione"
    t.integer "eta"
    t.integer "patron_id"
    t.string  "gender",                      :limit => 1
    t.integer "numero_prestiti_in_clavis",                 :default => 0
    t.boolean "iscritto_clavis_stesso_anno",               :default => false
    t.date    "data_iscrizione_clavis"
    t.integer "differenza_giorni"
    t.integer "consultazioni_digitali"
    t.integer "prestiti_digitali"
    t.integer "registration_library_id"
    t.integer "preferred_library_id"
  end

  create_table "temp_mlol_prestiti", :id => false, :force => true do |t|
    t.string  "barcode",                        :limit => 24
    t.integer "prestiti_ebook"
    t.integer "prestiti_audiolibri"
    t.integer "eta"
    t.integer "patron_id"
    t.string  "gender",                         :limit => 1
    t.integer "numero_prestiti_in_clavis",                    :default => 0
    t.integer "numero_prestiti_in_clavis_2016",               :default => 0
    t.date    "data_iscrizione_clavis"
  end

  create_table "temp_piani", :id => false, :force => true do |t|
    t.integer "id",                          :null => false
    t.string  "piano",         :limit => 24
    t.string  "scaffale",      :limit => 24
    t.string  "palchetto",     :limit => 24
    t.string  "filtro_colloc", :limit => 36
  end

  create_table "temp_prestiti_goethe", :id => false, :force => true do |t|
    t.integer  "item_id"
    t.integer  "loan_id"
    t.string   "loan_status",     :limit => 1
    t.string   "value_label"
    t.datetime "loan_date_begin"
    t.datetime "loan_date_end"
    t.integer  "renew_count"
    t.float    "giorni"
  end

  create_table "temp_subjects", :id => false, :force => true do |t|
    t.text    "s1"
    t.text    "s2"
    t.string  "linktype", :limit => 20
    t.integer "seq"
  end

  create_table "test", :id => false, :force => true do |t|
    t.datetime "created_by"
    t.text     "nota"
  end

  create_table "topics_cloud", :id => false, :force => true do |t|
    t.text    "namespace"
    t.text    "intestazione"
    t.integer "id"
    t.integer "count",        :limit => 8
  end

  create_table "topografico_non_in_clavis", :force => true do |t|
    t.text     "bid"
    t.integer  "id_copia"
    t.integer  "id_titolo"
    t.integer  "home_library_id"
    t.string   "inventory_serie_id", :limit => 128
    t.integer  "inventory_number"
    t.text     "collocazione"
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
    t.integer  "container_id"
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

  create_table "work_stations", :force => true do |t|
    t.integer "clavis_library_id"
    t.string  "processor",         :limit => 2
    t.string  "location",          :limit => 80
    t.integer "monitor_id"
  end

  create_table "xhr_requests", :force => true do |t|
    t.string   "ip"
    t.string   "target"
    t.string   "qs"
    t.datetime "timestamp"
  end

end
