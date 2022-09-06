# coding: utf-8
Clavisbct::Application.routes.draw do

  resources :manoscritti
  resources :serial_titles do
    collection do
      get 'print'
    end
  end
  resources :serial_subscriptions
  resources :serial_libraries
  resources :serial_invoices

  resources :serial_lists do
    member do
      get 'import'
      put 'import'
      get 'clone'
      put 'clone'
      get 'add_library'
      delete 'delete_library'
      delete 'delete_titles'
    end
  end


  resources :work_stations do
    member do
      get 'bookmarks'
      put 'bookmarks_save'
    end
  end


  resources :bio_iconografico_topics


  resources :clavis_purchase_proposals

  resources :omeka_files, only:[:index,:upload] do
    collection do
      get 'upload'
      post 'upload'
    end
  end

  resources :clavis_item_requests, only:[:index] do
  end

  
  resources :dng_shelves, only:[:index,:show] do
  end

  resources :dng_sessions, only:[:index,:show] do
  end

  resources :omeka_items, only:[:index,:show] do
  end

  resources :omeka_collections, only:[:index,:show] do
  end

  resources :bct_letters do
    collection do
      get 'random_letter'
      get 'static_intro'
    end
  end
  resources :bct_people
  resources :bct_places

  resources :adabas_inventories

  resources :extra_cards do
    member do
      post 'record_duplicate'
      post 'remove_from_container'
    end
    collection do
      get 'upload_xls'
      post 'upload_xls'
    end
  end

  resources :open_shelf_items do
    member do
      get 'insert'
      get 'delete'
    end
    collection do
      get 'titles'
      get 'estrazione_da_magazzino'
      get 'conteggio'
    end
  end

  resources :container_items

  resources :clavis_libraries

  resources :containers do
    collection do
      get 'barcodes'
    end
  end

  devise_for :users
  scope "/minad" do
    resources :users
  end

  devise_for :clavis_patrons

  match 'jsonip' => 'home#jsonip'
  match 'logxhr' => 'home#logxhr'

  match 'obj/:id/:key' => 'd_objects#objshow'

  # match 'ccu/:user/:pass/:clientip' => 'clavis_patrons#user_checkin_notification'
  match 'ccu/:user/:pass/:ip' => 'clavis_patrons#user_checkin_notification'

  resources :d_objects do
    collection do
      get 'random_mp3'
      get 'upload'
      post 'upload'
    end
    member do
      get 'download'
      get 'list_folder_content'
      get 'view'
      get 'dnl'
      get 'dnl_pdf'
      get 'set_as_cover_image'
    end
  end

  # resources :clavis_patrons, only: [:show] do
  resources :clavis_patrons do
    collection do
      get 'purchase_proposals_count'
      get 'mancato_ritiro'
      get 'stat'
      get 'duplicates'
    end
    member do
      post 'csir_insert'
      get 'autocert'
      get 'loans_analysis'
    end
  end

  resources :d_objects_folders, only: [:index,:show,:edit,:update,:destroy] do
    member do
      post 'makepdf'
      get 'makepdf'
      get 'makedir'
      put 'makedir'
      get 'filenames'
      get 'set_pdf_params'
      get 'derived'
      get 'download'
      delete 'delete_contents'
    end
  end

  resources :bctcards, only: [:index,:show]

  resources :bio_iconografico_cards do
    collection do
      get 'upload'
      post 'upload'
      get 'numera'
      get 'intesta'
      delete 'delete'
      get 'info'
    end
  end

  resources :subjects do
    collection do
      get 'duplicate_terms'
    end
  end

  resources :bncf_terms do
    collection do
      get 'obsolete_terms'
      get 'missing_terms'
    end
  end

  resources :talking_books do
    member do
      get 'download_mp3'
    end
    collection do
      get 'opac_edit_intro'
      post 'opac_edit_intro'
      get 'search'
      get 'check'
      get 'check_duplicates'
      get 'build_pdf'
      get 'digitalizzati'
      get 'digitalizzati_non_presenti'
      get 'stats'
    end
  end

  resources :talking_book_readers do
  end

  resources :identity_cards do
    member do
      get 'newuser_show'
      get 'newuser_docview'
      get 'docview'
    end
  end

  resources :iss_journals do
    collection do
      get 'infopage'
    end
  end
  resources :iss_issues do
    member do
      get 'toc'
      get 'cover_image'
    end
  end
  resources :iss_articles
  resources :iss_pages

  resources :audio_visuals


  resources :sp_bibliographies do
    member do
      get 'cover_image'
      get 'check_items'
      get 'clavisbct_include'
    end
    collection do
      get 'admin'
      get 'users'
      put 'add_user'
      post 'add_user'
    end
  end

  resources :sp_sections
  resources :sp_items do
    collection do
      get 'ricollocati_a_scaffale_aperto'
    end
    member do
      get 'info'
    end
  end

  match '/checkdewey' => 'home#checkdewey'  
  match '/uni856' => 'home#uni856'
  match '/er' => 'home#url_sbn'
  match '/bcd' => 'home#dup_barcodes'
  match '/verifica_consistenze' => 'clavis_consistency_notes#index'

  match '/or', to: 'identity_cards#new'
  match '/or_create', to: 'identity_cards#create', via: [:post]
  match '/ors/:unique_id', to: 'identity_cards#newuser_show'
  
  match '/procultura' => 'procultura_folders#index'

  resources :procultura_cards
  resources :procultura_folders

  resources :ordini do
    collection do
      get 'fatture'
    end
  end

  resources :clavis_manifestations do
    member do
      get 'kardex'
      get 'testpdf'
      get 'attachments'
      get 'sbn_opac_redir'
      get 'sbn_iccu_opac_redir'
      get 'check_adabas_kardex'
      get 'containers'
    end
    collection do
      get 'shortlist'
      get 'attachments_list'
      get 'libriparlati_con_audio'
      get 'bid_duplicati'
      get 'piuprestati'
    end
  end

  resources :clavis_loans do
    collection do
      get 'receipts'
      get 'view_goethe_loans'
      get 'loans_by_supplier'
    end
  end

  resources :clavis_items do
    member do
      get 'sync'
      get 'info'
    end
    collection do
      get 'collocazioni'
      get 'ricollocazioni'
      post 'closed_stack_item_request'
      get 'fifty_years'
      get 'controllo_valori_inventariali'
      get 'clear_user_data'
      get 'find_by_home_library_id_and_manifestation_ids'
      get 'senza_copertina'
    end
  end

  resources :clavis_issues do
    collection do
      get 'check'
      get 'lastin'
    end
  end

  resources :clavis_consistency_notes do
    collection do
      get 'details'
      get 'list_by_manifestation_id'
    end
  end

  resources :excel_files
  resources :excel_sheets

  resources :clavis_authorities do
    collection do
      get 'info'
      get 'dupl'
    end
  end

  resources :schema_collocazioni_centrales, only: [:index, :show, :edit, :update, :new, :create, :destroy] do
    collection do
      get 'see'
      get 'list'
    end
  end

  resources :closed_stack_item_requests, only: [:index,:show,:destroy] do
    member do
      get 'item_delete'
      get 'csir_delete'
      get 'csir_archive'
    end
    collection do
      get 'check'
      get 'random_insert'
      get 'print'
      get 'autoprint'
      get 'autoprint_requests'
      get 'confirm_request'
      get 'search'
      get 'stats'
    end
  end

  resources :clavis_librarians, only: [:index,:show] do
  end

  resources :sbct_titles do
    member do
      get 'add_to_library'
    end
    collection do
      get 'piurichiesti'
      get 'users'
    end
  end

  resources :sbct_items do
    collection do
      post 'create_order'
      get 'orders'
    end
  end

  resources :sbct_lists do
    collection do
      get 'upload'
      post 'upload'
    end
    member do
      get 'report'
      get 'do_order'
      get 'associa_a_budget'
    end
  end
  resources :sbct_budgets

  resources :sbct_suppliers

  resources :sbct_invoices, only: [:index,:show] do
    collection do
      get 'upload'
      post 'upload'
    end
  end

  match '/periodici_e_fatture' => 'clavis_items#periodici_e_fatture'
  match '/periodici_ordini' => 'clavis_manifestations#periodici_ordini'
  match '/metasearch' => 'metasearch#search'
  match '/redir' => 'metasearch#redir'

  match '/test' => 'home#test'
  match '/bidcr' => 'home#bidcr'

  match '/iccu' => 'home#iccu_link'

  match '/spazioragazzi' => 'home#spazioragazzi'
  
  match '/senzasoggetto' => 'home#senzasoggetto'

  match 'esemplari_con_rfid', to: 'home#esemplari_con_rfid', via: [:get]

  match '/sa' => 'clavis_items#ricollocazioni'

  match '/cr' => 'sbct_titles#homepage'

  match '/pmr' => 'home#periodici_musicale_in_ritardo'

  match '/cipes' => 'cipes_cedo_records#index'

  match '/cp_wc' => 'clavis_patrons#wrong_contacts'

  get 'controllo_provincia/:city/:province', to: 'home#controllo_provincia'

  get 'getpdf/:manifestation_id', to: 'home#getpdf'

  get 'cces/', to: 'home#confronto_consistenze_esemplari'

  get 'cercafc', to: 'clavis_items#cerca_fuoricatalogo'

  get 'spl/:manifestation_id', to: 'sp_items#redir'

  root :to => 'home#index'
end
