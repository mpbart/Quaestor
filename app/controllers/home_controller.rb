# frozen_string_literal: true

class HomeController < ApplicationController
  before_action :authenticate_user!

  def index
    @accounts = current_user.accounts
    @transactions = current_user.paginated_transactions(page_num: params[:page]&.to_i || 1)
                                .includes(:account, :plaid_category)
  end
end
