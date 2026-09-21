require "rails_helper"

RSpec.describe "Leads", type: :request do
  let(:customer) { create(:customer) }

  describe "GET /leads" do
    it "renders the index" do
      create(:lead, customer: customer)
      get leads_path
      expect(response).to have_http_status(:success)
    end

    it "filters by the search query across title/customer name" do
      match_customer = create(:customer, first_name: "Zebra", last_name: "Findme")
      match    = create(:lead, customer: match_customer, title: "Kitchen retile")
      no_match = create(:lead, customer: customer, title: "Bathroom job")

      get leads_path, params: { q: { title_or_customer_first_name_or_customer_last_name_cont: "Findme" } }

      expect(response.body).to include(match.title)
      expect(response.body).not_to include(no_match.title)
    end

    it "filters by status using the enum's integer value, not its label" do
      # Regression test: Ransack's *_eq predicate doesn't understand Rails enums - it
      # naively casts a non-numeric string label via #to_i (e.g. "contacted".to_i == 0),
      # which would silently match "new" leads instead of raising. The <select> must
      # submit Lead.statuses' integer values, not the string keys.
      new_lead       = create(:lead, customer: customer, status: :new)
      contacted_lead = create(:lead, customer: customer, status: :contacted)

      get leads_path, params: { q: { status_eq: Lead.statuses["contacted"] } }

      expect(response.body).to include(contacted_lead.title)
      expect(response.body).not_to include(new_lead.title)
    end

    it "paginates when there are more leads than one page" do
      leads = create_list(:lead, 21, customer: customer)
      last_lead = leads.max_by(&:id)

      get leads_path
      expect(response.body).to include("page=2")
      expect(response.body).not_to include(last_lead.title)

      get leads_path, params: { page: 2 }
      expect(response.body).to include(last_lead.title)
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

  describe "restyled UI (Step 9)" do
    it "index: renders the page header, a status badge per row, and the row-actions popover trigger" do
      lead = create(:lead, customer: customer, status: :contacted)
      get leads_path

      expect(response.body).to include('<h1 class="text-xl font-semibold text-base-content">Leads</h1>')
      expect(response.body).to include('href="' + new_lead_path + '"')
      expect(response.body).to match(/badge badge-soft badge-info">\s*Contacted/)
      expect(response.body).to include("popovertarget=\"row-actions-lead_#{lead.id}\"")
    end

    it "show: renders the detail list, description block, and (when present) the related Job and Quotes" do
      lead = create(:lead, customer: customer, description: "Wants the whole kitchen redone")
      job = create(:job, :from_lead, lead: lead, customer: customer)
      quote = create(:quote, lead: lead, customer: customer)

      get lead_path(lead)

      expect(response.body).to include('<dt class="text-xs font-semibold uppercase tracking-wide text-base-content/70">Customer</dt>')
      expect(response.body).to include("Wants the whole kitchen redone")
      expect(response.body).to include(job.title)
      expect(response.body).to include(quote.quote_number)
      expect(response.body).to include('href="' + new_lead_quote_path(lead) + '"')
    end

    it "show: renders an empty state for Quotes and omits the Job section when there is no job" do
      lead = create(:lead, customer: customer)
      get lead_path(lead)

      expect(response.body).to include("No quotes yet.")
      expect(response.body).not_to include(">Job<")
    end

    it "form: has a blank prompt on the Customer select and None on Job Type/Source" do
      get new_lead_path

      expect(response.body).to match(%r{<option value="">Select a customer</option>})
      expect(response.body.scan('<option value="">None</option>').size).to eq(2)
    end
  end
end
