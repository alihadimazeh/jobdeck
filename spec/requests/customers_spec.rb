require "rails_helper"

RSpec.describe "Customers", type: :request do
  describe "GET /customers" do
    it "renders the index" do
      create(:customer)
      get customers_path
      expect(response).to have_http_status(:success)
    end

    it "excludes archived customers" do
      visible  = create(:customer, status: :active)
      archived = create(:customer, status: :archived)

      get customers_path

      expect(response.body).to include(visible.full_name)
      expect(response.body).not_to include(archived.full_name)
    end
  end

  describe "GET /customers/:id" do
    it "renders the customer" do
      customer = create(:customer)
      get customer_path(customer)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /customers/new" do
    it "renders the form" do
      get new_customer_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /customers/:id/edit" do
    it "renders the form" do
      customer = create(:customer)
      get edit_customer_path(customer)
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /customers" do
    let(:valid_params) { { customer: { first_name: "Ada", last_name: "Lovelace", phone: "555-0100" } } }

    it "creates a customer and redirects to it" do
      expect { post customers_path, params: valid_params }.to change(Customer, :count).by(1)
      expect(response).to redirect_to(customer_path(Customer.last))
    end

    it "re-renders the form on blank required fields" do
      params = { customer: { first_name: "", last_name: "", phone: "" } }
      expect { post customers_path, params: params }.not_to change(Customer, :count)
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /customers/:id" do
    it "updates and redirects" do
      customer = create(:customer)
      patch customer_path(customer), params: { customer: { first_name: "Updated" } }
      expect(response).to redirect_to(customer_path(customer))
      expect(customer.reload.first_name).to eq("Updated")
    end

    it "re-renders the form on blank required fields" do
      customer = create(:customer)
      patch customer_path(customer), params: { customer: { first_name: "" } }
      expect(response).to have_http_status(:unprocessable_content)
      expect(customer.reload.first_name).not_to eq("")
    end
  end

  describe "DELETE /customers/:id" do
    it "destroys the customer and redirects when nothing blocks it" do
      customer = create(:customer)
      expect { delete customer_path(customer) }.to change(Customer, :count).by(-1)
      expect(response).to redirect_to(customers_path)
    end

    it "archives instead of destroying when the customer has a job" do
      customer = create(:customer)
      create(:job, customer: customer)

      expect { delete customer_path(customer) }.not_to change(Customer, :count)
      expect(response).to redirect_to(customers_path)
      expect(flash[:notice]).to eq("This customer has history and can't be deleted — archived instead.")
      expect(customer.reload).to be_archived_status
    end
  end
end
