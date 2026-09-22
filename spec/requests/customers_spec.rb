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

    it "filters by the search query across name/phone/email" do
      match     = create(:customer, first_name: "Zebra", last_name: "Findme")
      no_match  = create(:customer, first_name: "Other", last_name: "Person")

      get customers_path, params: { q: { first_name_or_last_name_or_phone_or_email_cont: "Findme" } }

      expect(response.body).to include(match.full_name)
      expect(response.body).not_to include(no_match.full_name)
    end

    it "paginates when there are more customers than one page" do
      customers = create_list(:customer, 21)
      last_customer = customers.max_by(&:id)

      get customers_path
      expect(response.body).to include("page=2")
      expect(response.body).not_to include(last_customer.full_name)

      get customers_path, params: { page: 2 }
      expect(response).to have_http_status(:success)
      expect(response.body).to include(last_customer.full_name)
    end
  end

  describe "GET /customers/:id" do
    it "renders the customer" do
      customer = create(:customer)
      get customer_path(customer)
      expect(response).to have_http_status(:success)
    end

    it "renders Edit and Delete actions" do
      customer = create(:customer)
      get customer_path(customer)

      expect(response.body).to include(">Edit<")
      expect(response.body).to include(">Delete<")
      expect(response.body).to include(customer_path(customer))
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
    it "re-renders with a field error for a malformed email" do
      params = { customer: { first_name: "A", last_name: "B", phone: "555", email: "nope" } }
      expect { post customers_path, params: params }.not_to change(Customer, :count)
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Email is invalid")
    end

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

  describe "restyled UI (Step 8 - daisyUI components, not just old markup that happens to say Edit/Delete)" do
    it "index: renders the page header, a status badge per row, and the row-actions popover trigger" do
      customer = create(:customer, status: :active)
      get customers_path

      expect(response.body).to include('<h1 class="text-xl font-semibold text-base-content">Customers</h1>')
      expect(response.body).to include('href="' + new_customer_path + '"')
      expect(response.body).to match(/badge badge-soft badge-success">\s*Active/)
      expect(response.body).to include("popovertarget=\"row-actions-customer_#{customer.id}\"")
    end

    it "index: renders the empty state with a working call to action when there are no customers" do
      # test/fixtures/customers.yml rows can be sitting in the shared test DB from a
      # Minitest run (RSpec's per-example rollback doesn't touch data already
      # committed before its transaction started) - clear explicitly for a true empty
      # case. disable_referential_integrity so leftover fixture jobs/leads/etc that
      # reference these customers don't FK-block the delete.
      ActiveRecord::Base.connection.disable_referential_integrity { Customer.delete_all }
      get customers_path
      expect(response.body).to include("No customers yet.")
      expect(response.body).to include('href="' + new_customer_path + '"')
    end

    it "show: renders the detail list, the stats block, and a status badge" do
      customer = create(:customer, status: :inactive)
      create(:job, customer: customer)

      get customer_path(customer)

      expect(response.body).to include('<dt class="text-xs font-semibold uppercase tracking-wide text-base-content/70">Phone</dt>')
      expect(response.body).to include("stats stats-vertical")
      expect(response.body).to include("stat-value")
      expect(response.body).to match(/badge badge-soft badge-neutral">\s*Inactive/)
    end

    it "form: renders labeled daisyUI inputs and links a failed-submit's errors to their fields" do
      post customers_path, params: { customer: { first_name: "", last_name: "", phone: "" } }

      expect(response.body).to include('id="form-errors"')
      expect(response.body).to include('role="alert"')
      expect(response.body).to include('data-controller="autofocus"')
      expect(response.body).to include('href="#customer_first_name"')
      expect(response.body).to include('aria-invalid="true"')
      expect(response.body).to include('class="label" for="customer_first_name"')
    end
  end
end
