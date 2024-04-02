# frozen_string_literal: true

class BalancesController < ApplicationController
  def create
    account = ::Account.find(params[:balance][:account_id])
    # TODO: Refactor this when adding a repository/persistence layer
    # Ignore available balance and limit when manually creating balances
    balance = FinanceManager::Account::BalanceStruct.new(
      BigDecimal(params[:balance][:balance]),
      0,
      0
    )
    FinanceManager::Account.create_balance(account, balance)
    render json: { success: true }
  rescue StandardError => e
    render json: { success: false, error: e }
  end
end
