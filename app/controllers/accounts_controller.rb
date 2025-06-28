# frozen_string_literal: true

require 'finance_manager/analytics'

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

  def balance_history
    end_date = Date.current
    start_date = end_date - 11.months
    balance_data = FinanceManager::Analytics.account_balance_history(
      user_id:    current_user.id,
      account_id: params[:id],
      start_date: start_date.to_s,
      end_date:   end_date.to_s
    )
    render json: balance_data
  end

  def subtypes
    render json: { subtypes: Account::ACCOUNT_TYPES[params[:subtype]] }
  end
end
