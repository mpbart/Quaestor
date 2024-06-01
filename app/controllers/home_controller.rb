# frozen_string_literal: true

class HomeController < ApplicationController
  before_action :authenticate_user!

  def index
    @accounts = current_user.accounts
    @transactions = current_user.paginated_transactions(page_num: params[:page]&.to_i || 1)
                                .includes(:account, :plaid_category)
    @net_worth = Account.net_worth(current_user.id)
    @income_by_source = [["Wages", 5000.0], ["Interest", 100.0]] #TODO
    @expenses_by_source = [["Mortgage", 1826.23], ["Groceries", 1112.91]] # TODO
  end
end
