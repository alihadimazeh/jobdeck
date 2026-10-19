class AccountSetupsController < ApplicationController
  layout "auth"
  allow_unauthenticated_access
  before_action :set_user_by_token, only: %i[edit update]

  def edit
  end

  def update
    if @user.update(password_params)
      start_new_session_for(@user)
      redirect_to root_path, notice: "Welcome! Your password has been set."
    else
      redirect_to edit_account_setup_path(params[:token]), alert: @user.errors.full_messages.to_sentence
    end
  end

  private

  def set_user_by_token
    @user = User.find_by_token_for(:account_setup, params[:token])
    redirect_to new_session_path, alert: "That invite link is invalid or has expired." unless @user
  end

  def password_params
    params.permit(:password, :password_confirmation)
  end
end
