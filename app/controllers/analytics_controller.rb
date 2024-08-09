# frozen_string_literal: true

require 'finance_manager/analytics'

class AnalyticsController < ApplicationController
  before_action :authenticate_user!

  def index; end

  def chart_data
    data_set = params.permit(:dataset)[:dataset]
    # TODO: make all parameters keyword args so that we can dynamically pass in
    # different numbers of args to the analytics methods
    results = if ['spending_on_merchant_over_timeframe'].include?(data_set)
                FinanceManager::Analytics.try(data_set, 'meijer', nil, current_user.id)
              else
                FinanceManager::Analytics.try(data_set, nil, current_user.id)
              end
    render json: results || {}
  end
end
