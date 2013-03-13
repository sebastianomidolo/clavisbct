Clavisbct::Application.routes.draw do


  resources :talking_books


  match '/procultura' => 'procultura_folders#index'
  resources :procultura_cards
  resources :procultura_folders

  # devise_for :users

  resources :clavis_manifestations do
    member do
      get 'kardex'
      get 'testpdf'
    end
    collection do
      get 'shortlist'
    end
  end

  resources :clavis_loans do
    collection do
      get 'receipts'
    end
  end

  resources :clavis_items do
  end


  match '/metasearch' => 'metasearch#search'
  match '/redir' => 'metasearch#redir'

  match '/spazioragazzi' => 'home#spazioragazzi'


  root :to => 'home#index'
end
