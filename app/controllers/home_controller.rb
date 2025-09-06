# frozen_string_literal: true

require 'finance_manager/transaction/calculations'

class HomeController < ApplicationController
  before_action :authenticate_user!

  def index
    filtered_params = params.permit(:start_date, :end_date)
    @start_date = filtered_params[:start_date] || 30.days.ago.to_date
    @end_date = filtered_params[:end_date] || Date.current
    @accounts = current_user.accounts
    @net_worth = Account.net_worth(current_user.id)
    @calcs = FinanceManager::Transaction::Calculations.new(current_user)
    @total_income = @calcs.total_amount(@calcs.income_by_source(@start_date, @end_date))
    @total_expenses = @calcs.total_amount(@calcs.expenses_by_source(@start_date, @end_date))
    @primary_categories = PlaidCategory.pluck(:primary_category).uniq.sort
  end

  def transactions_by_type
    start_date = params[:start_date]
    end_date = params[:end_date]
    calcs = FinanceManager::Transaction::Calculations.new(current_user)
    transactions = if params[:type] == 'income'
                     calcs.income_transactions(start_date, end_date)
                   else
                     calcs.expense_transactions(start_date, end_date)
                   end

    transactions = if params[:category_type] == 'recurring'
                     calcs.recurring(transactions)
                   else
                     calcs.non_recurring(transactions)
                   end

    transactions_hash = transactions.order(amount: :desc).map do |t|
      t.as_json(include: :plaid_category)
       .merge(humanized_category: humanized_category(t.plaid_category))
    end
    render json: transactions_hash
  end
end
