class PasswordsMailer < ApplicationMailer
  def reset(user)
    @user = user
    @token = user.generate_token_for(:password_reset)
    mail subject: "Reset your Jobdeck password", to: user.email
  end
end
