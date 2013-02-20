Clavisbct::Application.routes.draw do

  resources :clavis_manifestation do
    member do
      get 'kardex'
    end
  end

  match '/metasearch' => 'metasearch#search'
  match '/redir' => 'metasearch#redir'

end
