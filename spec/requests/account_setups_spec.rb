require "rails_helper"

RSpec.describe "Account setups", type: :request, skip_authentication: true do
  describe "GET /account_setups/:token/edit" do
    it "renders the set-password form for a valid token" do
      user = create(:user)
      token = user.generate_token_for(:account_setup)

      get edit_account_setup_path(token)
      expect(response).to have_http_status(:success)
    end

    it "redirects for an invalid token" do
      get edit_account_setup_path("bogus-token")
      expect(response).to redirect_to(new_session_path)
    end
  end

  describe "PATCH /account_setups/:token" do
    it "sets the password and signs the user in" do
      user = create(:user)
      token = user.generate_token_for(:account_setup)

      expect {
        patch account_setup_path(token), params: { password: "newpassword123", password_confirmation: "newpassword123" }
      }.to change { user.reload.sessions.count }.by(1)

      expect(response).to redirect_to(root_path)
      expect(User.authenticate_by(email: user.email, password: "newpassword123")).to eq(user)
    end

    it "re-renders with an error when the passwords don't match" do
      user = create(:user)
      token = user.generate_token_for(:account_setup)

      patch account_setup_path(token), params: { password: "newpassword123", password_confirmation: "different" }

      expect(response).to redirect_to(edit_account_setup_path(token))
    end

    it "rejects an expired or tampered token" do
      patch account_setup_path("bogus-token"), params: { password: "newpassword123", password_confirmation: "newpassword123" }
      expect(response).to redirect_to(new_session_path)
    end

    it "can't be replayed once the password has been set" do
      user = create(:user)
      token = user.generate_token_for(:account_setup)
      patch account_setup_path(token), params: { password: "newpassword123", password_confirmation: "newpassword123" }

      patch account_setup_path(token), params: { password: "again12345", password_confirmation: "again12345" }
      expect(response).to redirect_to(new_session_path)
    end
  end
end
