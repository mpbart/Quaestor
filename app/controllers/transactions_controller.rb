class TransactionsController < ApplicationController
  before_action :authenticate_user!

  def index
    @transactions = current_user.paginated_transactions(page_num: 1)
  end

end
