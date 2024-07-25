# frozen_string_literal: true

require 'finance_manager/analytics'

class AnalyticsController < ApplicationController
  before_action :authenticate_user!

  def index; end

  def chart_data
    data_set = params.permit(:dataset)[:dataset]
    results = FinanceManager::Analytics.try(data_set, nil, current_user.id)
    render json: results || {}
  end
end
