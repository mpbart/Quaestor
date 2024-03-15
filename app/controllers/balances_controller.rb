# frozen_string_literal: true

class BalancesController < ApplicationController
  def create
    account = ::Account.find(params[:balance][:account_id])
    FinanceManager::Account.create_balance(account, params[:balance])
  rescue StandardError => e
    render json: { success: false, error: e }
  end
end
