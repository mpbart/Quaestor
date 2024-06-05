# frozen_string_literal: true

class ApplicationController < ActionController::Base
  helper_method :short_format_date, :amount_class
  helper_method :humanized_category, :label_id_to_color

  IDX_TO_COLOR = {
    1 => 'blue',
    2 => 'brown',
    3 => 'purple',
    4 => 'orange'
  }.freeze

  def short_format_date(date)
    date.strftime('%b %e')
  end

  def humanized_category(plaid_category)
    plaid_category.detailed_category[plaid_category.primary_category.length + 1..].humanize
  end

  def label_id_to_color(idx)
    IDX_TO_COLOR[idx]
  end
end
