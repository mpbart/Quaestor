# frozen_string_literal: true

require 'finance_manager/analytics'

class AnalyticsController < ApplicationController
  before_action :authenticate_user!

  def index; end

  def chart_data
    data_set = params.permit(
      :dataset, :start_date, :end_date, :category, :label_id, :merchant_name,
      exclude_account_ids: [], exclude_label_ids: [], exclude_categories: [], exclude_merchants: []
    )
    params = {
      category_name: data_set[:category],
      merchant_name: data_set[:merchant_name],
      user_id:       data_user.id,
      label_id:      data_set[:label_id],
      start_date:    data_set[:start_date],
      end_date:      data_set[:end_date],
      exclusions:    exclusions_from(data_set)
    }.compact
    results = FinanceManager::Analytics.compute_analytics(data_set[:dataset], params)
    render json: results || {}
  end

  private

  def exclusions_from(data_set)
    {
      account_ids: data_set[:exclude_account_ids],
      label_ids:   data_set[:exclude_label_ids],
      categories:  data_set[:exclude_categories],
      merchants:   data_set[:exclude_merchants]
    }.transform_values { |values| Array(values).compact_blank.presence }.compact.presence
  end
end
