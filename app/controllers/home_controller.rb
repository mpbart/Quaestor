class HomeController < ApplicationController
  before_action :authenticate_user!

  def index
    @links ||= []
    @tweets ||= []
  end

end
