Clavisbct::Application.routes.draw do
  match '/metasearch' => 'metasearch#search'
  match '/redir' => 'metasearch#redir'
end
