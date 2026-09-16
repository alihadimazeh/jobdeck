require "rails_helper"

RSpec.describe "layouts/_sidebar", type: :view do
  it "renders the brand mark and a primary nav landmark with links to every top-level section" do
    render partial: "layouts/sidebar"

    expect(rendered).to have_selector("span", text: "Jobdeck")
    expect(rendered).to have_selector("nav[aria-label='Primary'] ul.menu")
    expect(rendered).to have_selector("nav[aria-label='Primary'] a[href='/customers']", text: "Customers")
    expect(rendered).to have_selector("nav[aria-label='Primary'] a[href='/leads']", text: "Leads")
    expect(rendered).to have_selector("nav[aria-label='Primary'] a[href='/jobs']", text: "Jobs")
  end
end
