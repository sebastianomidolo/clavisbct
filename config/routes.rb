Clavisbct::Application.routes.draw do

  resources :work_stations


  resources :bio_iconografico_topics


  resources :clavis_purchase_proposals

  resources :omeka_files, only:[:index,:upload] do
    collection do
      get 'upload'
      post 'upload'
    end
  end

  resources :dng_shelves, only:[:index,:show] do
  end
  
  resources :omeka_items, only:[:index,:show] do
  end

  resources :omeka_collections, only:[:index,:show] do
  end

  resources :bct_letters do
    collection do
      get 'random_letter'
    end
  end
  resources :bct_people
  resources :bct_places

  resources :extra_cards do
    member do
      post 'record_duplicate'
      post 'remove_from_container'
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
      get 'set_as_cover_image'
    end
  end

  resources :clavis_patrons, only: [:index] do
    member do
      get 'print_request'
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
    end
  end
  
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
      get 'check'
      get 'check_duplicates'
      get 'build_pdf'
      get 'digitalizzati'
      get 'digitalizzati_non_presenti'
    end
  end
  resources :iss_articles
  resources :audio_visuals


  resources :sp_bibliographies do
    member do
      get 'cover_image'
      get 'check_items'
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

  match '/uni856' => 'home#uni856'
  match '/verifica_consistenze' => 'clavis_consistency_notes#index'

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
    end
  end

  resources :clavis_loans do
    collection do
      get 'receipts'
      get 'view_goethe_loans'
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
    end
  end

  resources :schema_collocazioni_centrales, only: [:index, :show, :edit, :update, :new, :create, :destroy] do
    collection do
      get 'see'
      get 'list'
    end
  end

  resources :closed_stack_item_requests, only: [:index,:show] do
    member do
      get 'item_delete'
    end
    collection do
      get 'check'
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

  match '/pmr' => 'home#periodici_musicale_in_ritardo'

  match '/cipes' => 'cipes_cedo_records#index'

  match '/cp_wc' => 'clavis_patrons#wrong_contacts'

  get 'controllo_provincia/:city/:province', to: 'home#controllo_provincia'

  get 'getpdf/:manifestation_id', to: 'home#getpdf'

  
  root :to => 'home#index'
end
