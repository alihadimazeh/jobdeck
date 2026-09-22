require "rails_helper"

RSpec.describe "Passwords", type: :request, skip_authentication: true do
  describe "GET /passwords/new" do
    it "renders the reset request form" do
      get new_password_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /passwords" do
    it "queues a reset email for a known address" do
      user = create(:user)

      expect {
        post passwords_path, params: { email: user.email }
      }.to have_enqueued_mail(PasswordsMailer, :reset)

      expect(response).to redirect_to(new_session_path)
    end

    it "gives the same response for an unknown address (no account enumeration)" do
      post passwords_path, params: { email: "nobody@example.com" }
      expect(response).to redirect_to(new_session_path)
      follow_redirect!
      expect(response.body).to include("If that email is in our system")
    end
  end

  describe "GET /passwords/:token/edit" do
    it "renders the reset form for a valid token" do
      user = create(:user)
      token = user.generate_token_for(:password_reset)

      get edit_password_path(token)
      expect(response).to have_http_status(:success)
    end

    it "redirects for an invalid token" do
      get edit_password_path("bogus-token")
      expect(response).to redirect_to(new_password_path)
    end
  end

  describe "PATCH /passwords/:token" do
    it "updates the password and redirects to sign in" do
      user = create(:user, password: "password123", password_confirmation: "password123")
      token = user.generate_token_for(:password_reset)

      patch password_path(token), params: { password: "newpassword123", password_confirmation: "newpassword123" }

      expect(response).to redirect_to(new_session_path)
      expect(User.authenticate_by(email: user.email, password: "newpassword123")).to eq(user)
    end

    it "re-renders with an error when the passwords don't match" do
      user = create(:user)
      token = user.generate_token_for(:password_reset)

      patch password_path(token), params: { password: "newpassword123", password_confirmation: "different" }

      expect(response).to redirect_to(edit_password_path(token))
    end

    it "rejects an expired or tampered token" do
      patch password_path("bogus-token"), params: { password: "newpassword123", password_confirmation: "newpassword123" }
      expect(response).to redirect_to(new_password_path)
    end
  end
end
