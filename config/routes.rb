Clavisbct::Application.routes.draw do

  resources :procultura_folders


  devise_for :users

  resources :clavis_manifestation do
    member do
      get 'kardex'
      get 'testpdf'
    end
  end

  resources :clavis_loan do
    collection do
      get 'receipts'
    end
  end


  match '/metasearch' => 'metasearch#search'
  match '/redir' => 'metasearch#redir'


  root :to => 'home#index'
end
