class AccountsController < ApplicationController
  def create
    FinanceManager::Account.create_manually(params[:account], current_user)
  end

  def subtypes
    render json: { subtypes: Account::ACCOUNT_TYPES[params[:subtype]] }
  end
end
