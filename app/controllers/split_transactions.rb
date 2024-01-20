# frozen_string_literal: true

class SplitTransactionsController < ApplicationController
  include ActionView::Helpers::NumberHelper

  before_action :authenticate_user!

  def show
    @split_transaction = SplitTransaction.find(id)
  end
end
