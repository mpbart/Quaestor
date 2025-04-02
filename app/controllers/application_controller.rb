# frozen_string_literal: true

class ApplicationController < ActionController::Base
  helper_method :short_format_date, :amount_class
  helper_method :humanized_category, :label_id_to_color
  helper_method :progress_bar_colors, :make_value_readable

  CURRENT_YEAR = Date.current.year.freeze

  IDX_TO_COLOR = {
    1 => 'blue',
    2 => 'brown',
    3 => 'purple',
    4 => 'orange'
  }.freeze

  PROGRESS_BAR_COLORS = %w[
    #3ad081
    #fdd643
    #5d7ce8
    #f85c6a
    #c6d533
    #00d8d6
    #f5c8d8
  ].freeze

  def short_format_date(date)
    if date.year == CURRENT_YEAR
      date.strftime('%b %e')
    else
      date.strftime('%b %e, %Y')
    end
  end

  def humanized_category(plaid_category)
    plaid_category.detailed_category[plaid_category.primary_category.length + 1..].humanize
  end

  def label_id_to_color(idx)
    IDX_TO_COLOR[idx]
  end

  def progress_bar_colors
    PROGRESS_BAR_COLORS
  end

  def make_value_readable(val, field_name)
    case field_name
    when 'account_id'
      Account.find(val).name
    when 'label_id'
      Label.find(val).name
    when 'plaid_category_id'
      humanized_category(PlaidCategory.find(val))
    else
      val
    end
  end
end
