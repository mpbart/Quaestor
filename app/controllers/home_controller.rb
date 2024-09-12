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
  end
end
