# frozen_string_literal: true

class RulesController < ApplicationController
  before_action :authenticate_user!

  def index
    @transaction_rules = TransactionRule.all.to_a
  end

  def create
    puts params
  end
end
