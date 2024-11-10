# frozen_string_literal: true

class LabelsController < ApplicationController
  def create
    label = ::Label.find_by(name: params[:label][:name])
    raise StandardError('Label already exists!') if label

    ::Label.create!(name: params[:label][:name])
    render json: { success: true }
  rescue StandardError => e
    render json: { success: false, error: e }
  end
end
