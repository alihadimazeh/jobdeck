class SessionsController < ApplicationController
  layout "auth"
  allow_unauthenticated_access only: %i[new create]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: "Too many attempts. Try again in a few minutes." }

  def new
  end

  def create
    if user = User.authenticate_by(email: params[:email], password: params[:password])
      start_new_session_for(user, remember: params[:remember_me] == "1")
      redirect_to after_authentication_url, notice: "Signed in."
    else
      redirect_to new_session_path, alert: "Incorrect email or password."
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path, notice: "Signed out."
  end
end
