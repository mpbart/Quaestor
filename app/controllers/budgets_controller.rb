# frozen_string_literal: true

class BudgetsController < ApplicationController
  before_action :authenticate_user!

  def index; end
end
