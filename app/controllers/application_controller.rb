class ApplicationController < ActionController::Base
  helper_method :short_format_date, :amount_class

  def short_format_date(date)
    date.strftime('%b %e')
  end

end
