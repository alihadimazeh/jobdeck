require "rails_helper"

RSpec.describe "Sessions", type: :request, skip_authentication: true do
  describe "GET /session/new" do
    it "renders the sign-in form" do
      get new_session_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /session" do
    it "signs in with correct credentials and redirects to the app" do
      user = create(:user, password: "password123", password_confirmation: "password123")

      post session_path, params: { email: user.email, password: "password123" }

      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include("Signed in.")
    end

    it "sends the visitor back to the page they were trying to reach" do
      user = create(:user, password: "password123", password_confirmation: "password123")

      get customers_path
      expect(response).to redirect_to(new_session_path)

      post session_path, params: { email: user.email, password: "password123" }
      expect(response).to redirect_to(customers_path)
    end

    it "rejects an incorrect password" do
      user = create(:user, password: "password123", password_confirmation: "password123")

      post session_path, params: { email: user.email, password: "wrong" }

      expect(response).to redirect_to(new_session_path)
      follow_redirect!
      expect(response.body).to include("Incorrect email or password.")
    end

    it "rejects a non-existent email" do
      post session_path, params: { email: "nobody@example.com", password: "whatever" }
      expect(response).to redirect_to(new_session_path)
    end
  end

  describe "DELETE /session" do
    it "signs the user out and blocks further access to protected pages" do
      user = create(:user, password: "password123", password_confirmation: "password123")
      post session_path, params: { email: user.email, password: "password123" }

      delete session_path
      expect(response).to redirect_to(new_session_path)

      get customers_path
      expect(response).to redirect_to(new_session_path)
    end
  end

  describe "authentication requirement" do
    it "redirects an unauthenticated visitor away from a protected page" do
      get customers_path
      expect(response).to redirect_to(new_session_path)
    end

    it "allows an authenticated visitor through" do
      user = create(:user, password: "password123", password_confirmation: "password123")
      post session_path, params: { email: user.email, password: "password123" }

      get customers_path
      expect(response).to have_http_status(:success)
    end
  end
end
