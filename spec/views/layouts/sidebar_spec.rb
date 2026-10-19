require "rails_helper"

RSpec.describe "layouts/_sidebar", type: :view do
  it "renders the brand mark and a primary nav landmark with links to every top-level section" do
    view.define_singleton_method(:authenticated?) { false }
    render partial: "layouts/sidebar"

    expect(rendered).to have_selector("span", text: "Jobdeck")
    expect(rendered).to have_selector("nav[aria-label='Primary'] ul.menu")
    expect(rendered).to have_selector("nav[aria-label='Primary'] a[href='/']", text: "Dashboard")
    expect(rendered).to have_selector("nav[aria-label='Primary'] a[href='/customers']", text: "Customers")
    expect(rendered).to have_selector("nav[aria-label='Primary'] a[href='/leads']", text: "Leads")
    expect(rendered).to have_selector("nav[aria-label='Primary'] a[href='/jobs']", text: "Jobs")
  end

  it "shows the signed-in user's email and a sign-out button when authenticated" do
    user = build_stubbed(:user, email: "pm@example.com")
    view.define_singleton_method(:authenticated?) { true }
    view.define_singleton_method(:current_user) { user }
    render partial: "layouts/sidebar"

    expect(rendered).to have_selector("p", text: "pm@example.com")
    expect(rendered).to have_selector("button", text: "Sign out")
  end

  it "shows the Users nav link to an admin" do
    user = build_stubbed(:user, :admin)
    view.define_singleton_method(:authenticated?) { true }
    view.define_singleton_method(:current_user) { user }
    render partial: "layouts/sidebar"

    expect(rendered).to have_selector("nav[aria-label='Primary'] a[href='/users']", text: "Users")
  end

  it "hides the Users nav link from a non-admin" do
    user = build_stubbed(:user, :project_manager)
    view.define_singleton_method(:authenticated?) { true }
    view.define_singleton_method(:current_user) { user }
    render partial: "layouts/sidebar"

    expect(rendered).not_to have_selector("nav[aria-label='Primary'] a", text: "Users")
  end
end
