# frozen_string_literal: true

require 'finance_manager/interface'

class TransactionRefreshWorker
  include Sidekiq::Worker

  def perform
    return if transactions_refreshed_today?

    ::User.joins(:plaid_credentials).distinct.each do |user|
      Rails.logger.info("Refreshing transactions for User ID: #{user.id}")
      ::FinanceManager::Interface.new(user).refresh_transactions
    end
  end

  private

  def transactions_refreshed_today?
    newest_response = PlaidResponse.order(created_at: :desc).first
    newest_response&.created_at&.to_date == Date.current
  end
end
