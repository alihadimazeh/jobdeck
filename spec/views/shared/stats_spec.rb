require "rails_helper"

RSpec.describe "shared/_stats", type: :view do
  it "renders a stat block per item" do
    render partial: "shared/stats", locals: {
      items: [
        { title: "Active Jobs", value: 3 },
        { title: "Leads", value: 7, desc: "2 need follow-up" }
      ]
    }
    expect(rendered).to have_selector("div.stats div.stat", count: 2)
    expect(rendered).to have_selector(".stat-title", text: "Active Jobs")
    expect(rendered).to have_selector(".stat-value", text: "3")
    expect(rendered).to have_selector(".stat-desc", text: "2 need follow-up")
  end
end
