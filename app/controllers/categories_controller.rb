# frozen_string_literal: true

class CategoriesController < ApplicationController
  def create
    category = ::PlaidCategory.find_by(
      primary_category:  params[:plaid_category][:primary_category],
      detailed_category: params[:plaid_category][:detailed_category]
    )
    raise StandardError('Category already exists!') if category

    formatted_primary = format_category(params[:plaid_category][:primary_category])
    formatted_detailed = format_category(
      formatted_primary + '_' + format_category(params[:plaid_category][:detailed_category])
    )
    ::PlaidCategory.create!(
      primary_category:  formatted_primary,
      detailed_category: formatted_detailed,
      description:       params[:plaid_category][:description]
    )
    render json: { success: true }
  rescue StandardError => e
    render json: { success: false, error: e }
  end

  def format_category(cat)
    cat.tr(' ', '_').upcase
  end
end
