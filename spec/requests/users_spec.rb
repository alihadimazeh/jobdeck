require "rails_helper"

RSpec.describe "Users", type: :request do
  # The global before(:each, type: :request) hook (spec/support/authentication.rb)
  # signs in as create(:user), which defaults to role :admin - exactly who should
  # be allowed here, so no explicit sign_in_as is needed for the "as admin" cases.

  describe "GET /users" do
    it "renders the index" do
      create(:user, :sales, email: "staff@example.com")
      get users_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("staff@example.com")
    end
  end

  describe "GET /users/:id" do
    it "renders the user" do
      user = create(:user, :sales)
      get user_path(user)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /users/new" do
    it "renders the form" do
      get new_user_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /users/:id/edit" do
    it "renders the form" do
      user = create(:user, :sales)
      get edit_user_path(user)
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /users" do
    let(:valid_params) { { user: { email: "newhire@example.com", role: "sales" } } }

    it "creates a user and redirects to it" do
      expect { post users_path, params: valid_params }.to change(User, :count).by(1)
      expect(response).to redirect_to(user_path(User.last))
      expect(User.last.role).to eq("sales")
    end

    it "queues an invite email" do
      expect { post users_path, params: valid_params }.to have_enqueued_mail(UsersMailer, :invite)
    end

    it "re-renders the form on an invalid email" do
      params = { user: { email: "not-an-email", role: "sales" } }
      expect { post users_path, params: params }.not_to change(User, :count)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "ignores a submitted password - the server always generates one" do
      params = { user: { email: "newhire@example.com", role: "sales", password: "hacked123", password_confirmation: "hacked123" } }
      post users_path, params: params

      expect(User.authenticate_by(email: "newhire@example.com", password: "hacked123")).to be_nil
    end
  end

  describe "PATCH /users/:id" do
    it "updates email/role and redirects" do
      user = create(:user, :sales)
      patch user_path(user), params: { user: { email: "changed@example.com", role: "project_manager" } }

      expect(response).to redirect_to(user_path(user))
      expect(user.reload.email).to eq("changed@example.com")
      expect(user.role).to eq("project_manager")
    end

    it "ignores a submitted password - only self-service reset can set one" do
      user = create(:user, :sales, password: "original123", password_confirmation: "original123")
      patch user_path(user), params: { user: { email: user.email, role: "sales", password: "hacked123", password_confirmation: "hacked123" } }

      expect(User.authenticate_by(email: user.email, password: "original123")).to eq(user)
    end

    it "blocks an admin from changing their own role away from admin" do
      admin = create(:user, :admin)
      sign_in_as(admin)

      patch user_path(admin), params: { user: { email: admin.email, role: "viewer" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(admin.reload.role).to eq("admin")
    end
  end

  describe "as a non-admin" do
    %i[sales project_manager viewer].each do |role|
      context "signed in as #{role}" do
        before { sign_in_as(create(:user, role)) }

        it "is denied on every action" do
          target = create(:user, :sales)

          get users_path
          expect(response).to redirect_to(root_path)

          get user_path(target)
          expect(response).to redirect_to(root_path)

          get new_user_path
          expect(response).to redirect_to(root_path)

          get edit_user_path(target)
          expect(response).to redirect_to(root_path)

          expect { post users_path, params: { user: { email: "x@example.com", role: "sales" } } }.not_to change(User, :count)
          expect(response).to redirect_to(root_path)

          patch user_path(target), params: { user: { email: "changed@example.com" } }
          expect(response).to redirect_to(root_path)
          expect(target.reload.email).not_to eq("changed@example.com")
        end
      end
    end
  end
end
