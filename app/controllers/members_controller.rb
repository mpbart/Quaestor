# frozen_string_literal: true

class MembersController < ApplicationController
  before_action :authenticate_user!
  before_action :require_owner!

  def index
    @members = current_user.members.order(:email)
    @member = current_user.members.build
  end

  def create
    @member = current_user.members.build(params.require(:user).permit(:email, :password))
    if @member.save
      redirect_to members_path, notice: 'Household member added.'
    else
      @members = current_user.members.order(:email)
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    current_user.members.find(params[:id]).destroy!
    redirect_to members_path, notice: 'Household member removed.', status: :see_other
  end
end
