# frozen_string_literal: true

class AccountsController < ApplicationController
  def create
    FinanceManager::Account.create_manually(params[:account], current_user)
    render json: { success: true }
  rescue StandardError => e
    render json: { success: false, error: e }
  end

  def show
    @account = Account.find(params[:id])
  end

  def subtypes
    render json: { subtypes: Account::ACCOUNT_TYPES[params[:subtype]] }
  end
end
