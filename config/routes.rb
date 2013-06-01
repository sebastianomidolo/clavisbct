Clavisbct::Application.routes.draw do

  match 'obj/:id/:key' => 'd_objects#objshow'

  resources :d_objects


  resources :subjects

  resources :talking_books
  resources :iss_articles


  resources :sp_bibliographies
  resources :sp_sections
  resources :sp_items

  match '/procultura' => 'procultura_folders#index'
  resources :procultura_cards
  resources :procultura_folders

  # devise_for :users

  resources :clavis_manifestations do
    member do
      get 'kardex'
      get 'testpdf'
      get 'attachments'
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
