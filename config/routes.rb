Rails.application.routes.draw do
  devise_for :users, controllers: {
                      sessions:      'users/sessions',
                      registrations: 'users/registrations'}

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root 'home#index'

  post '/get_access_token', to: 'plaid#get_access_token'
end
