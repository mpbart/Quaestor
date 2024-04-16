# frozen_string_literal: true

class ApplicationController < ActionController::Base
  helper_method :short_format_date, :amount_class
  helper_method :humanized_category, :label_idx_to_color

  IDX_TO_COLOR = {
    0 => "blue",
    1 => "brown",
    2 => "purple",
    3 => "orange",
  }

  def short_format_date(date)
    date.strftime('%b %e')
  end

  def humanized_category(plaid_category)
    plaid_category.detailed_category[plaid_category.primary_category.length + 1..].humanize
  end

  def label_idx_to_color(idx)
    IDX_TO_COLOR[idx]
  end
end
