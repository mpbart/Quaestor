# frozen_string_literal: true

class RulesController < ApplicationController
  before_action :authenticate_user!

  def index; end
end
