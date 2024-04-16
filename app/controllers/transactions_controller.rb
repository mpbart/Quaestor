# frozen_string_literal: true

require 'finance_manager/interface'

class TransactionsController < ApplicationController
  include ActionView::Helpers::NumberHelper

  before_action :authenticate_user!

  def index
    @transactions = FinanceManager::Transaction.search(current_user, params)
  end

  def show
    @transaction = @transactions&.detect do |t|
      t.id == params[:id]
    end || Transaction.find(params[:id])
    @label_ids = Set.new(@transaction.labels.pluck(:id))
    @grouped_transactions = @transaction.grouped_transactions
    @split_transaction = if @grouped_transactions.empty?
                           ::Transaction.new
                         else
                           @grouped_transactions.build
                         end
  end

  def update
    permitted = params.require(:transaction).permit(
      :date,
      :amount,
      :description,
      :plaid_category_id,
      label_ids:          [],
      split_transactions: [:date, :amount,
                           :description, :plaid_category_id, :_destroy]
    )
    transaction = Transaction.find(params[:id])
    success = if params[:split_transactions].nil?
                transaction.update(permitted)
              else
                finance_manager.transactions.split_transaction(params[:id],
                                                               params[:split_transactions])
              end

    render json: { success: success }
  end

  # Split a single transaction into multiple
  def split_transactions
    new_transaction_details = params.require(:transaction).permit(:date, :amount, :description,
                                                                  :parent_transaction_id).to_h
    parent_transaction_id = new_transaction_details.delete(:parent_transaction_id)
    result = finance_manager.split_transaction!(parent_transaction_id, new_transaction_details)
    render json: { success: result }
  end

  # Upload a CSV of transactions
  def upload_csv
    current_user.transaction_csvs.attach(params[:user][:transaction_csv])
    finance_manager.import_transactions_csv(current_user.transaction_csvs.last)
  end

  def hard_delete
    Transaction.find(params[:transaction_id]).destroy_fully!

    redirect_to action: 'index'
  end

  private

  def finance_manager
    @finance_manager ||= FinanceManager::Interface.new(current_user)
  end
end
