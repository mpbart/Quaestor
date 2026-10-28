# frozen_string_literal: true

require 'finance_manager/analytics'

class AccountsController < ApplicationController
  before_action :authenticate_user!

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

  def mark_inactive
    account = current_user.accounts.find(params[:id])
    account.update!(inactive: true)
    render json: { success: true }
  rescue ActiveRecord::RecordNotFound
    render json: { success: false }, status: :not_found
  end

  def rename
    account = current_user.accounts.find(params[:id])
    account.update!(name: params.require(:name))
    render json: { success: true }
  rescue ActiveRecord::RecordNotFound
    render json: { success: false }, status: :not_found
  end

  def backup
    DatabaseBackupWorker.perform_async(current_user.id)
    render json: { success: true }
  end
end
