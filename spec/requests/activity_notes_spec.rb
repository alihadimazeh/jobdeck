require "rails_helper"

RSpec.describe "ActivityNotes", type: :request do
  let(:customer) { create(:customer) }
  let(:lead)     { create(:lead, customer: customer) }

  describe "POST /leads/:lead_id/activity_notes" do
    it "creates a note on the lead and redirects to it" do
      params = { activity_note: { body: "Called the customer", author: "Jane" } }
      expect { post lead_activity_notes_path(lead), params: params }.to change(ActivityNote, :count).by(1)

      expect(response).to redirect_to(lead_path(lead))
      note = ActivityNote.last
      expect(note.notable).to eq(lead)
      expect(note.author).to eq("Jane")
    end

    it "redirects back to the parent with an alert on invalid params, without creating anything" do
      params = { activity_note: { body: "" } }
      expect { post lead_activity_notes_path(lead), params: params }.not_to change(ActivityNote, :count)

      expect(response).to redirect_to(lead_path(lead))
      expect(flash[:alert]).to eq("Body can't be blank")
    end
  end

  describe "POST /jobs/:job_id/activity_notes" do
    it "creates a note on the job and redirects to it" do
      job = create(:job, customer: customer)
      params = { activity_note: { body: "Site visit scheduled" } }

      expect { post job_activity_notes_path(job), params: params }.to change(ActivityNote, :count).by(1)
      expect(response).to redirect_to(job_path(job))
      expect(ActivityNote.last.notable).to eq(job)
    end
  end

  describe "POST /orders/:order_id/activity_notes" do
    it "creates a note on the order and redirects to it" do
      job   = create(:job, customer: customer)
      order = create(:order, job: job, customer: customer)
      params = { activity_note: { body: "Materials delivered" } }

      expect { post order_activity_notes_path(order), params: params }.to change(ActivityNote, :count).by(1)
      expect(response).to redirect_to(order_path(order))
      expect(ActivityNote.last.notable).to eq(order)
    end
  end

  describe "GET /activity_notes/:id/edit" do
    it "renders the edit form inside the matching turbo-frame" do
      note = lead.activity_notes.create!(body: "Original body")
      get edit_activity_note_path(note)

      expect(response).to have_http_status(:success)
      expect(response.body).to include(%(id="#{ActionView::RecordIdentifier.dom_id(note)}"))
      expect(response.body).to include("Original body")
    end
  end

  describe "PATCH /activity_notes/:id" do
    it "updates the note and redirects to its parent, status: see_other" do
      note = lead.activity_notes.create!(body: "Original body")
      patch activity_note_path(note), params: { activity_note: { body: "Updated body" } }

      expect(response).to redirect_to(lead_path(lead))
      expect(response).to have_http_status(:see_other)
      expect(note.reload.body).to eq("Updated body")
    end

    it "re-renders the edit form in the same frame with a 422 on invalid params" do
      note = lead.activity_notes.create!(body: "Original body")
      patch activity_note_path(note), params: { activity_note: { body: "" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include(%(id="#{ActionView::RecordIdentifier.dom_id(note)}"))
      expect(note.reload.body).to eq("Original body")
    end
  end

  describe "DELETE /activity_notes/:id" do
    it "destroys the note and redirects to its parent" do
      note = lead.activity_notes.create!(body: "Original body")

      expect { delete activity_note_path(note) }.to change(ActivityNote, :count).by(-1)
      expect(response).to redirect_to(lead_path(lead))
    end
  end

  describe "inline rendering on the parent's show page" do
    it "shows the empty state when there are no notes, and the note once one exists" do
      get lead_path(lead)
      expect(response.body).to include("No activity yet.")

      note = lead.activity_notes.create!(body: "Called the customer")
      get lead_path(lead)

      expect(response.body).not_to include("No activity yet.")
      expect(response.body).to include("Called the customer")
      expect(response.body).to include(%(id="#{ActionView::RecordIdentifier.dom_id(note)}"))
    end
  end

  describe "POST /customers/:customer_id/activity_notes" do
    it "creates a note on the customer and redirects to it" do
      params = { activity_note: { body: "Prefers morning calls" } }
      expect { post customer_activity_notes_path(customer), params: params }.to change(ActivityNote, :count).by(1)

      expect(response).to redirect_to(customer_path(customer))
      expect(ActivityNote.last.notable).to eq(customer)
    end

    it "does not create a note on invalid params" do
      expect {
        post customer_activity_notes_path(customer), params: { activity_note: { body: "" } }
      }.not_to change(ActivityNote, :count)
    end
  end

  describe "editing/deleting a customer's note" do
    let!(:note) { create(:activity_note, notable: customer, body: "Old") }

    it "updates it and redirects back to the customer" do
      patch activity_note_path(note), params: { activity_note: { body: "New" } }
      expect(response).to redirect_to(customer_path(customer))
      expect(note.reload.body).to eq("New")
    end

    it "deletes it and redirects back to the customer" do
      expect { delete activity_note_path(note) }.to change(ActivityNote, :count).by(-1)
      expect(response).to redirect_to(customer_path(customer))
    end
  end
end
