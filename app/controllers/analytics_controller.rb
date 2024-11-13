# frozen_string_literal: true

require 'finance_manager/analytics'

class AnalyticsController < ApplicationController
  before_action :authenticate_user!

  def index; end

  def chart_data
    data_set = params.permit(
      :dataset, :start_date, :end_date, :category, :label_id, :merchant_name
    )
    params = {
      category_name: data_set[:category],
      merchant_name: data_set[:merchant_name],
      user_id:       current_user.id,
      label_id:      data_set[:label_id],
      start_date:    data_set[:start_date],
      end_date:      data_set[:end_date],
    }.compact
    results = FinanceManager::Analytics.try(data_set[:dataset], **params)
    render json: results || {}
  end
end
