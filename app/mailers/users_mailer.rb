class UsersMailer < ApplicationMailer
  def invite(user)
    @user = user
    @token = user.generate_token_for(:account_setup)
    mail subject: "You've been invited to Jobdeck", to: user.email
  end
end
