# frozen_string_literal: true

class AnalyticsController < ApplicationController
  before_action :authenticate_user!

  def index; end
end
