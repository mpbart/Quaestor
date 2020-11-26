class HomeController < ApplicationController
  before_action :authenticate_user!

  def index
    @accounts ||= current_user.accounts
    @transactions = current_user.paginated_transactions(page_num: 1)
  end

end
