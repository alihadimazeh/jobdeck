require "rails_helper"

RSpec.describe "shared/_page_header", type: :view do
  it "renders just the heading when no breadcrumbs are given" do
    render partial: "shared/page_header", locals: { title: "Leads" }
    expect(rendered).to have_selector("h1", text: "Leads")
    expect(rendered).not_to have_selector("nav[aria-label='Breadcrumb']")
  end

  it "suppresses the breadcrumb nav when its last item duplicates the title (U4)" do
    render partial: "shared/page_header", locals: { title: "Leads", breadcrumbs: [ [ "Leads", nil ] ] }
    expect(rendered).not_to have_selector("nav[aria-label='Breadcrumb']")
    expect(rendered).to have_selector("h1", text: "Leads")
  end

  it "renders the breadcrumb trail when its last segment differs from the title" do
    # e.g. an edit page: trail ends in "Edit", heading is "Edit Kitchen Remodel"
    render partial: "shared/page_header", locals: {
      title: "Edit Kitchen Remodel",
      breadcrumbs: [ [ "Leads", "/leads" ], [ "Kitchen Remodel", "/leads/1" ], [ "Edit", nil ] ]
    }
    expect(rendered).to have_selector("nav[aria-label='Breadcrumb'] a[href='/leads']", text: "Leads")
    expect(rendered).to have_selector("nav[aria-label='Breadcrumb'] a[href='/leads/1']", text: "Kitchen Remodel")
    expect(rendered).to have_selector("h1", text: "Edit Kitchen Remodel")
  end

  it "renders a primary action button" do
    render partial: "shared/page_header", locals: {
      title: "Leads", action: { label: "New Lead", path: "/leads/new" }
    }
    expect(rendered).to have_selector("a.btn.btn-primary[href='/leads/new']", text: "New Lead")
  end

  it "prefers the actions slot over a single action when both are given" do
    render partial: "shared/page_header", locals: {
      title: "Leads",
      action: { label: "New Lead", path: "/leads/new" },
      actions: "<button>Custom</button>".html_safe
    }
    expect(rendered).to have_selector("button", text: "Custom")
    expect(rendered).not_to have_selector("a", text: "New Lead")
  end
end
