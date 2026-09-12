require "rails_helper"

RSpec.describe "Leads", type: :request do
  let(:customer) { create(:customer) }

  describe "GET /leads" do
    it "renders the index" do
      create(:lead, customer: customer)
      get leads_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /leads/:id" do
    it "renders the lead" do
      lead = create(:lead, customer: customer)
      get lead_path(lead)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /leads/new" do
    it "renders the form" do
      get new_lead_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /leads/:id/edit" do
    it "renders the form" do
      lead = create(:lead, customer: customer)
      get edit_lead_path(lead)
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /leads" do
    it "creates a lead and redirects to it" do
      params = { lead: { title: "New lead", customer_id: customer.id } }
      expect { post leads_path, params: params }.to change(Lead, :count).by(1)
      expect(response).to redirect_to(lead_path(Lead.last))
    end

    it "re-renders the form on invalid params" do
      params = { lead: { title: "", customer_id: customer.id } }
      expect { post leads_path, params: params }.not_to change(Lead, :count)
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /leads/:id" do
    it "updates and redirects" do
      lead = create(:lead, customer: customer)
      patch lead_path(lead), params: { lead: { title: "Updated title" } }
      expect(response).to redirect_to(lead_path(lead))
      expect(lead.reload.title).to eq("Updated title")
    end

    it "re-renders the form on invalid params" do
      lead = create(:lead, customer: customer)
      patch lead_path(lead), params: { lead: { title: "" } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "DELETE /leads/:id" do
    it "destroys the lead and redirects when nothing blocks it" do
      lead = create(:lead, customer: customer)
      expect { delete lead_path(lead) }.to change(Lead, :count).by(-1)
      expect(response).to redirect_to(leads_path)
    end

    it "redirects with an alert and does not destroy when the lead has an order" do
      lead = create(:lead, customer: customer)
      job  = create(:job, customer: customer, lead: lead)
      create(:order, job: job, customer: customer, lead: lead)

      expect { delete lead_path(lead) }.not_to change(Lead, :count)
      expect(response).to redirect_to(leads_path)
      expect(flash[:alert]).to eq("Could not delete lead.")
    end
  end
end
