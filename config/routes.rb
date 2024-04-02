# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users, controllers: {
    sessions:      'users/sessions',
    registrations: 'users/registrations'
  }

  # Home Page
  root 'home#index'

  # Plaid
  post '/get_access_token', to: 'plaid#get_access_token'
  post '/refresh_accounts', to: 'plaid#refresh_accounts'
  post '/create_link_token', to: 'plaid#create_link_token'
  post '/fix_account/:account_id', to: 'plaid#fix_account_connection'

  # Transactions
  resources :transactions, only: [:index, :show, :update] do
    post '/hard_delete', to: 'transactions#hard_delete'
  end
  resources :split_transactions, only: [:index, :show]
  resources :accounts, only: [:create, :show]
  resources :balances, only: [:create]

  get 'accounts/subtypes/:subtype', to: 'accounts#subtypes'
  post '/split_transactions', to: 'transactions#split_transactions'

  # Analytics
  get 'analytics',    to: 'analytics#index'

  # Budgets
  get 'budgets',      to: 'budgets#index'
end
