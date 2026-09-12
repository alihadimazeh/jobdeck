require "rails_helper"

RSpec.describe "Quotes", type: :request do
  let(:customer) { create(:customer) }
  let(:lead)     { create(:lead, customer: customer) }

  describe "GET /leads/:lead_id/quotes" do
    it "renders the index" do
      create(:quote, lead: lead, customer: customer)
      get lead_quotes_path(lead)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /quotes/:id" do
    it "renders the quote" do
      quote = create(:quote, lead: lead, customer: customer)
      get quote_path(quote)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /leads/:lead_id/quotes/new" do
    it "renders the form" do
      get new_lead_quote_path(lead)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /quotes/:id/edit" do
    it "renders the form" do
      quote = create(:quote, lead: lead, customer: customer)
      get edit_quote_path(quote)
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /leads/:lead_id/quotes" do
    let(:valid_params) do
      {
        quote: {
          tax_rate: 0,
          rooms_attributes: { "0" => { name: "Kitchen", length: 10, width: 12 } },
          quote_line_items_attributes: {
            "0" => { item_type: "material", description: "Tile", quantity: 2, unit: "sqft", unit_price: 5 }
          }
        }
      }
    end
    let(:invalid_params) do
      { quote: { quote_line_items_attributes: { "0" => { description: "", quantity: 0, unit_price: -1 } } } }
    end

    it "creates a quote and redirects to it" do
      expect { post lead_quotes_path(lead), params: valid_params }.to change(Quote, :count).by(1)
      expect(response).to redirect_to(quote_path(Quote.last))
    end

    it "re-renders the form on invalid params" do
      expect { post lead_quotes_path(lead), params: invalid_params }.not_to change(Quote, :count)
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /quotes/:id" do
    it "updates and redirects to the quote" do
      quote = create(:quote, lead: lead, customer: customer)
      patch quote_path(quote), params: { quote: { notes: "revised" } }
      expect(response).to redirect_to(quote_path(quote))
      expect(quote.reload.notes).to eq("revised")
    end
  end

  describe "DELETE /quotes/:id" do
    it "destroys the quote and redirects to the lead's quotes" do
      quote = create(:quote, lead: lead, customer: customer)
      expect { delete quote_path(quote) }.to change(Quote, :count).by(-1)
      expect(response).to redirect_to(lead_quotes_path(lead))
    end
  end

  describe "PATCH /quotes/:id/accept" do
    it "accepts the quote and converts the lead to a job" do
      quote = create(:quote, :with_line_items, lead: lead, customer: customer, status: :sent)

      patch accept_quote_path(quote)

      expect(response).to redirect_to(quote_path(quote))
      expect(flash[:notice]).to eq("Quote accepted — job created.")
      expect(lead.reload).to be_converted_status
      expect(lead.job).to be_present
    end

    it "redirects with a validation alert when another quote on the lead is already accepted" do
      create(:quote, :accepted, lead: lead, customer: customer)
      quote_b = create(:quote, lead: lead, customer: customer, status: :sent)

      patch accept_quote_path(quote_b)

      expect(response).to redirect_to(quote_path(quote_b))
      expect(flash[:alert]).to eq("Status already has an accepted quote for this lead")
      expect(quote_b.reload).to be_sent_status
    end

    it "redirects with an alert when the lead has already converted" do
      quote_a = create(:quote, :with_line_items, lead: lead, customer: customer, status: :sent)
      patch accept_quote_path(quote_a)
      quote_a.reload.update!(status: :rejected)

      quote_b = create(:quote, lead: lead, customer: customer, status: :sent)
      patch accept_quote_path(quote_b)

      expect(response).to redirect_to(quote_path(quote_b))
      expect(flash[:alert]).to eq("Could not convert this quote to a job: This lead has already been converted to a job")
      expect(Job.where(lead: lead).count).to eq(1)
    end
  end
end
