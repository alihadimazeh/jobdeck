require "rails_helper"

RSpec.describe "Orders", type: :request do
  let(:customer) { create(:customer) }
  let(:job)      { create(:job, customer: customer) }

  describe "GET /jobs/:job_id/orders" do
    it "renders the index" do
      create(:order, job: job, customer: customer)
      get job_orders_path(job)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /orders/:id" do
    it "renders the order" do
      order = create(:order, job: job, customer: customer)
      get order_path(order)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /jobs/:job_id/orders/new" do
    it "renders the form" do
      get new_job_order_path(job)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /orders/:id/edit" do
    it "renders the form" do
      order = create(:order, job: job, customer: customer)
      get edit_order_path(order)
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /jobs/:job_id/orders" do
    let(:valid_params) do
      {
        order: {
          tax_rate: 0,
          line_items_attributes: {
            "0" => { item_type: "material", description: "Tile", quantity: 2, unit: "sqft", unit_price: 5 }
          }
        }
      }
    end
    let(:invalid_params) do
      {
        order: {
          line_items_attributes: { "0" => { item_type: "material", description: "", quantity: 0, unit_price: -1 } }
        }
      }
    end

    it "creates an order and redirects to it" do
      expect { post job_orders_path(job), params: valid_params }.to change(Order, :count).by(1)
      expect(response).to redirect_to(order_path(Order.last))
    end

    it "re-renders the form on invalid params" do
      expect { post job_orders_path(job), params: invalid_params }.not_to change(Order, :count)
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /orders/:id" do
    it "updates and redirects" do
      order = create(:order, job: job, customer: customer)
      patch order_path(order), params: { order: { notes: "updated" } }
      expect(response).to redirect_to(order_path(order))
      expect(order.reload.notes).to eq("updated")
    end
  end

  describe "DELETE /orders/:id" do
    it "destroys the order and redirects to the job's orders" do
      order = create(:order, job: job, customer: customer)
      expect { delete order_path(order) }.to change(Order, :count).by(-1)
      expect(response).to redirect_to(job_orders_path(job))
    end
  end
end
