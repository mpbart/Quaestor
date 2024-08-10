# frozen_string_literal: true

require 'finance_manager/analytics'

class AnalyticsController < ApplicationController
  before_action :authenticate_user!

  def index; end

  def chart_data
    data_set = params.permit(:dataset, :timeframe, :category, :merchant_name)
    # TODO: make all parameters keyword args so that we can dynamically pass in
    # different numbers of args to the analytics methods
    results = if ['spending_on_merchant_over_timeframe'].include?(data_set[:dataset])
                FinanceManager::Analytics.try(data_set[:dataset], data_set[:merchant_name], nil,
                                              current_user.id)
              elsif ['spending_on_category_over_timeframe'].include?(data_set[:dataset])
                FinanceManager::Analytics.try(:spending_on_detailed_category_over_timeframe,
                                              data_set[:category], nil, current_user.id)
              else
                FinanceManager::Analytics.try(data_set[:dataset], nil, current_user.id)
              end
    render json: results || {}
  end
end
