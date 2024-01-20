# frozen_string_literal: true

class ApplicationController < ActionController::Base
  helper_method :short_format_date, :amount_class
  helper_method :humanized_category

  def short_format_date(date)
    date.strftime('%b %e')
  end

  def humanized_category(plaid_category)
    plaid_category.detailed_category[plaid_category.primary_category.length + 1..].humanize
  end
end
