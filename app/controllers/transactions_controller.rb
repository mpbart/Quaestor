class TransactionsController < ApplicationController
  include ActionView::Helpers::NumberHelper

  before_action :authenticate_user!

  def index
    @categories ||= PlaidCategory.grouped_by_top_level
    @transactions = current_user.paginated_transactions(page_num: 1).by_date
  end

  def show
    # TODO: fix this so that it doesn't need a db lookup every time
    @transaction = @transactions&.detect{ |t| t.id == params[:id] } || Transaction.find(params[:id])
    @split_transaction = @transaction.split_transactions.build
  end

  def update
    permitted = params.require(:transaction).permit(:date,
                                                    :amount,
                                                    :description,
                                                    :category_id,
                                                    split_transactions: [:date, :amount, :description, :category_id, :_destroy])
    transaction = Transaction.find(params[:id])
    succes = if params[:split_transactions].nil?
      transaction.update(permitted)
    else
      puts params[:split_transactions]
      finance_manager.transactions.split_transaction(params[:id], params[:split_transactions])
    end

    render json: {success: success}
  end

  # Split a single transaction into multiple
  def split_transaction
    transaction_id = params['transaction_id']
    new_transaction_details = params['new_transaction_details']
    result = finance_manager.transactions.split_transaction(transaction_id, new_transaction_details)
    render json: {success: result}
  end

  private

  def finance_manager
    @finance_manager ||= FinanceManager::Interface.new(current_user)
  end

end
