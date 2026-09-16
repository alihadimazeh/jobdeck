require "rails_helper"

RSpec.describe "shared/_empty_state", type: :view do
  it "renders a plain div by default" do
    render partial: "shared/empty_state", locals: { title: "No leads yet." }
    expect(rendered).to have_selector("div p", text: "No leads yet.")
    expect(rendered).not_to have_selector("tr")
  end

  it "wraps in <tr><td colspan> when colspan is given, for use inside a table body" do
    render partial: "shared/empty_state", locals: { title: "No leads yet.", colspan: 5 }
    expect(rendered).to have_selector("tr td[colspan='5'] p", text: "No leads yet.")
  end

  it "renders an optional message and CTA button" do
    render partial: "shared/empty_state", locals: {
      title: "No leads yet.",
      message: "Add your first one to get started.",
      cta: { label: "New Lead", path: "/leads/new" }
    }
    expect(rendered).to have_selector("p", text: "Add your first one to get started.")
    expect(rendered).to have_selector("a.btn.btn-ghost[href='/leads/new']", text: "New Lead")
  end
end
