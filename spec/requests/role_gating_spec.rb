require "rails_helper"

RSpec.describe "Role-based view gating", type: :request do
  include AuthenticationHelpers

  describe "Customer show" do
    let(:customer) { create(:customer) }

    it "shows Edit/Delete to sales" do
      sign_in_as(create(:user, :sales))
      get customer_path(customer)
      expect(response.body).to include("Edit")
      expect(response.body).to include("Delete")
    end

    it "hides Edit/Delete from viewer" do
      sign_in_as(create(:user, :viewer))
      get customer_path(customer)
      expect(response.body).not_to include("Edit")
      expect(response.body).not_to include("Delete")
    end
  end

  describe "Job show" do
    let(:job) { create(:job) }

    it "shows Edit/Delete/New Order to project_manager" do
      sign_in_as(create(:user, :project_manager))
      get job_path(job)
      expect(response.body).to include("Edit")
      expect(response.body).to include("Delete")
      expect(response.body).to include("New Order")
    end

    it "hides Edit/Delete/New Order from sales (read-only on jobs)" do
      sign_in_as(create(:user, :sales))
      get job_path(job)
      expect(response.body).not_to include("Edit")
      expect(response.body).not_to include("Delete")
      expect(response.body).not_to include("New Order")
    end
  end

  describe "Quote show" do
    let(:quote) { create(:quote, status: :draft) }

    it "shows Accept Quote/Edit/Delete to sales" do
      sign_in_as(create(:user, :sales))
      get quote_path(quote)
      expect(response.body).to include("Accept Quote")
      expect(response.body).to include("Edit")
      expect(response.body).to include("Delete")
    end

    it "hides Accept Quote/Edit/Delete from viewer" do
      sign_in_as(create(:user, :viewer))
      get quote_path(quote)
      expect(response.body).not_to include("Accept Quote")
      expect(response.body).not_to include("Edit")
      expect(response.body).not_to include("Delete")
    end
  end

  describe "ActivityNote add form" do
    let(:job) { create(:job) }

    it "renders for sales (allowed to note a read-only Job)" do
      sign_in_as(create(:user, :sales))
      get job_path(job)
      expect(response.body).to include("Add Note")
    end

    it "is hidden for viewer" do
      sign_in_as(create(:user, :viewer))
      get job_path(job)
      expect(response.body).not_to include("Add Note")
    end
  end

  describe "index 'New X' buttons" do
    it "shows New Customer to sales" do
      sign_in_as(create(:user, :sales))
      get customers_path
      expect(response.body).to include("New Customer")
    end

    it "hides New Customer from viewer" do
      sign_in_as(create(:user, :viewer))
      get customers_path
      expect(response.body).not_to include("New Customer")
    end
  end

  describe "Dashboard 'New Lead' button" do
    it "shows New Lead to sales" do
      sign_in_as(create(:user, :sales))
      get root_path
      expect(response.body).to include("New Lead")
    end

    it "hides New Lead from viewer" do
      sign_in_as(create(:user, :viewer))
      get root_path
      expect(response.body).not_to include("New Lead")
    end
  end

  describe "User role changes (admin only)" do
    # Brakeman flags permit(:email, :role) in UsersController; this is the request-level
    # proof that only an admin can reach it (see config/brakeman.ignore).
    %i[viewer sales project_manager].each do |role|
      it "rejects a #{role} trying to make themselves admin" do
        user = create(:user, role)
        sign_in_as(user)
        patch user_path(user), params: { user: { email: user.email, role: "admin" } }
        expect(response).to have_http_status(:redirect)
        expect(user.reload.role).to eq(role.to_s)
      end

      it "rejects a #{role} creating an admin account" do
        sign_in_as(create(:user, role))
        expect {
          post users_path, params: { user: { email: "sneaky@example.com", role: "admin" } }
        }.not_to change(User, :count)
      end
    end
  end
end
