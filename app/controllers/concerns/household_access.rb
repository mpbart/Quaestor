# frozen_string_literal: true

module HouseholdAccess
  extend ActiveSupport::Concern

  included do
    helper_method :data_user
  end

  private

  def data_user
    current_user.data_owner
  end

  def require_owner!
    return unless current_user.member?

    if request.format.json? || request.xhr?
      render json: { success: false }, status: :forbidden
    else
      redirect_back fallback_location: root_path, alert: 'Only the household owner can perform this action.'
    end
  end
end
