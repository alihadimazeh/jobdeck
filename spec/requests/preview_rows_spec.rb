require "rails_helper"

# Customer/Lead show pages render their related-record tables through the shared
# leads/_lead and jobs/_job row partials (compact mode: no Customer column, no actions),
# so a change to those rows can't silently drift between the index and the previews.
RSpec.describe "Related-record preview rows", type: :request do
  let(:customer) { create(:customer, first_name: "Rowena", last_name: "Preview") }

  def row(html, record)
    Nokogiri::HTML(html).at_css("tr##{ActionView::RecordIdentifier.dom_id(record)}")
  end

  it "renders the customer's leads and jobs via the shared partials, compact" do
    lead = create(:lead, customer: customer, follow_up_date: Date.new(2026, 10, 1))
    job  = create(:job, customer: customer, start_date: Date.new(2026, 10, 5))
    get customer_path(customer)

    [ lead, job ].each do |record|
      tr = row(response.body, record)
      expect(tr).to be_present
      expect(tr.css("td").size).to eq(3)
      expect(tr.at_css("a[href='#{customer_path(customer)}']")).to be_nil
      expect(tr.at_css("[popovertarget]")).to be_nil
    end
    expect(row(response.body, lead).text).to include("Oct")
  end

  it "renders a lead's related job via the shared partial, compact" do
    lead = create(:lead, customer: customer)
    job  = create(:job, :from_lead, lead: lead, customer: customer)
    get lead_path(lead)

    tr = row(response.body, job)
    expect(tr.css("td").size).to eq(3)
    expect(tr.at_css("[popovertarget]")).to be_nil
  end

  it "keeps the full row (customer column + actions) on the index pages" do
    lead = create(:lead, customer: customer)
    get leads_path

    tr = row(response.body, lead)
    expect(tr.css("td").size).to eq(5)
    expect(tr.at_css("a[href='#{customer_path(customer)}']")).to be_present
    expect(tr.at_css("[popovertarget='row-actions-#{ActionView::RecordIdentifier.dom_id(lead)}']")).to be_present
  end
end
