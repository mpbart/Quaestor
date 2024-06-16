# frozen_string_literal: true

require 'finance_manager/transaction'

class HomeController < ApplicationController
  before_action :authenticate_user!

  def index
    @accounts = current_user.accounts
    @transactions = current_user.paginated_transactions(page_num: params[:page]&.to_i || 1)
                                .includes(:account, :plaid_category)
    @net_worth = Account.net_worth(current_user.id)
    @income_by_source = FinanceManager::Transaction.income_by_source(current_user)
    @total_income = @income_by_source.sum { |_k, v| v.sum(&:first) }.abs.round(2)
    @expenses_by_source = FinanceManager::Transaction.expenses_by_source(current_user)
    @total_expenses = @expenses_by_source.sum { |_k, v| v.sum(&:first) }.round(2)
  end
end
