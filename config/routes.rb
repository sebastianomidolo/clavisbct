Clavisbct::Application.routes.draw do

  resources :container_items

  resources :clavis_libraries

  resources :containers do
    collection do
      get 'barcodes'
    end
  end


  devise_for :users

  devise_for :clavis_patrons

  match 'jsonip' => 'home#jsonip'

  match 'obj/:id/:key' => 'd_objects#objshow'

  # match 'ccu/:user/:pass/:clientip' => 'clavis_patrons#user_checkin_notification'
  match 'ccu/:user/:pass/:ip' => 'clavis_patrons#user_checkin_notification'

  resources :d_objects do
    collection do
      get 'random_mp3'
    end
  end


  resources :subjects

  resources :talking_books do
    member do
      get 'download_mp3'
    end
    collection do
      get 'digitalizzati'
    end
  end
  resources :iss_articles
  resources :audio_visuals


  resources :sp_bibliographies
  resources :sp_sections
  resources :sp_items

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
    end
    collection do
      get 'shortlist'
      get 'attachments_list'
      get 'libriparlati_con_audio'
    end
  end

  resources :clavis_loans do
    collection do
      get 'receipts'
    end
  end

  resources :clavis_items do
    collection do
      get 'collocazioni'
      get 'ricollocazioni'
    end
  end

  resources :clavis_issues do
    collection do
      get 'check'
    end
  end

  resources :clavis_consistency_notes do
    collection do
      get 'details'
    end
  end

  resources :excel_files
  resources :excel_sheets

  resources :clavis_authorities do
    collection do
      get 'info'
    end
  end

  match '/periodici_e_fatture' => 'clavis_items#periodici_e_fatture'
  match '/periodici_ordini' => 'clavis_manifestations#periodici_ordini'
  match '/metasearch' => 'metasearch#search'
  match '/redir' => 'metasearch#redir'

  match '/spazioragazzi' => 'home#spazioragazzi'

  match '/pmr' => 'home#periodici_musicale_in_ritardo'

  root :to => 'home#index'
end
