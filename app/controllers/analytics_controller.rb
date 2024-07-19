# frozen_string_literal: true
require 'finance_manager/analytics'

class AnalyticsController < ApplicationController
  before_action :authenticate_user!

  def index; end

  def chart_data
    data_set = params.permit(:dataset)[:dataset]
    Rails.logger.info(data_set)
    results = FinanceManager::Analytics.try(data_set, nil, current_user.id)
    Rails.logger.info(results)
    render json: results || {}
  end
end
