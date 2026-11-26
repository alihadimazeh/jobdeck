require "rails_helper"

RSpec.describe "Rescheduling a follow-up from the dashboard", type: :request do
  let(:stream) { { "Accept" => "text/vnd.turbo-stream.html" } }

  describe "PATCH /leads/:id/reschedule" do
    it "moves the follow-up date, removes the row, and refreshes the card's count" do
      lead  = create(:lead, follow_up_date: Date.current, status: :contacted)
      other = create(:lead, follow_up_date: Date.current, status: :contacted)
      new_date = Date.current + 3

      patch reschedule_lead_path(lead), params: { follow_up_date: new_date.iso8601 }, headers: stream

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(lead.reload.follow_up_date).to eq(new_date)
      expect(response.body).to include(%(action="remove" target="#{ActionView::RecordIdentifier.dom_id(lead, :dashboard_row)}"))
      expect(response.body).to match(%r{action="update" target="due_today_count"><template>#{Lead.follow_up_due_today.count}</template>})
      expect(response.body).not_to include('target="due_today_rows"')
      expect(response.body).not_to include('target="overdue_count"')
      expect(other.reload.follow_up_date).to eq(Date.current)
    end

    it "swaps in the empty state when the card's last row goes" do
      lead = create(:lead, follow_up_date: Date.current - 4, status: :contacted)
      Lead.where.not(id: lead.id).update_all(follow_up_date: nil)

      patch reschedule_lead_path(lead), params: { follow_up_date: (Date.current + 1).iso8601 }, headers: stream

      expect(response.body).to match(%r{action="update" target="overdue_count"><template>0</template>})
      expect(response.body).to include('target="overdue_rows"')
      expect(response.body).to include("No overdue follow-ups.")
    end

    it "rejects a missing or malformed date without touching the lead" do
      lead = create(:lead, follow_up_date: Date.current, status: :contacted)

      patch reschedule_lead_path(lead), params: { follow_up_date: "not-a-date" }, headers: stream

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Pick a date to reschedule to.")
      expect(lead.reload.follow_up_date).to eq(Date.current)
    end

    it "falls back to a redirect with a notice for a plain HTML request" do
      lead = create(:lead, follow_up_date: Date.current, status: :contacted)

      patch reschedule_lead_path(lead), params: { follow_up_date: (Date.current + 2).iso8601 }

      expect(response).to redirect_to(root_path)
      expect(flash[:notice]).to start_with("Follow-up moved to")
    end

    it "is denied to a viewer" do
      sign_in_as(create(:user, :viewer))
      lead = create(:lead, follow_up_date: Date.current, status: :contacted)

      patch reschedule_lead_path(lead), params: { follow_up_date: (Date.current + 2).iso8601 }, headers: stream

      expect(lead.reload.follow_up_date).to eq(Date.current)
    end
  end

  describe "the dashboard's reschedule button" do
    it "appears on Due Today and Overdue rows for a role that can edit leads" do
      sign_in_as(create(:user, :sales))
      due     = create(:lead, follow_up_date: Date.current, status: :contacted)
      overdue = create(:lead, follow_up_date: Date.current - 2, status: :contacted)

      get root_path

      expect(response.body).to include(%(action="#{reschedule_lead_path(due)}"))
      expect(response.body).to include(%(action="#{reschedule_lead_path(overdue)}"))
      expect(response.body).to include("Reschedule follow-up for #{due.customer.full_name}")
    end

    it "is hidden from a viewer" do
      sign_in_as(create(:user, :viewer))
      due = create(:lead, follow_up_date: Date.current, status: :contacted)

      get root_path

      expect(response.body).to include(due.title)
      expect(response.body).not_to include(reschedule_lead_path(due))
    end
  end
end
