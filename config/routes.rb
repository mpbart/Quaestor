Rails.application.routes.draw do
  devise_for :users, controllers: {
                      sessions:      'users/sessions',
                      registrations: 'users/registrations'}

  root 'home#index'

  post '/get_access_token', to: 'plaid#get_access_token'
  post '/refresh_accounts', to: 'plaid#refresh_accounts'
end
