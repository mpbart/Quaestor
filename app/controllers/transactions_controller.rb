class TransactionsController < ApplicationController
  include ActionView::Helpers::NumberHelper

  before_action :authenticate_user!

  def index
    @categories ||= PlaidCategory.grouped_by_top_level
    @transactions = current_user.paginated_transactions(page_num: 1).by_date
  end

  def show
    transaction = @transactions&.detect{ |t| t.id == params[:id] } || Transaction.find(params[:id])
    render json: transaction.to_json
  end

  # Split a single transaction into multiple
  def split_transaction
    transaction_id = params['transaction_id']
    new_transaction_details = params['new_transaction_details']
    result = finance_manager.transactions.split_transaction(transaction_id, new_transaction_details)
    render json: {success: result}
  end

  # Updating any part of a single transaction
  def update_transaction
    transaction_id = params['transaction_id']
    new_transactino_details = params['new_transaction_details']
    result = finance_manager.transactions.edit_transaction(transaction_id, new_transaction_details)
    render json: {success: result}
  end

  private

  def finance_manager
    @finance_manager ||= FinanceManager::Interface.new(current_user)
  end

end
