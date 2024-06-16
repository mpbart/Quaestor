# frozen_string_literal: true

require 'finance_manager/transaction/calculations'

class HomeController < ApplicationController
  before_action :authenticate_user!

  def index
    @accounts = current_user.accounts
    @transactions = current_user.paginated_transactions(page_num: params[:page]&.to_i || 1)
                                .includes(:account, :plaid_category)
    @net_worth = Account.net_worth(current_user.id)
    @calcs = FinanceManager::Transaction::Calculations.new(current_user)
    @total_income = @calcs.grouped_by_source(@calcs.income_by_source)
    @total_expenses = @calcs.grouped_by_source(@calcs.expenses_by_source)
  end
end
