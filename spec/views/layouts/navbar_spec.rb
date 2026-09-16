require "rails_helper"

RSpec.describe "layouts/_navbar", type: :view do
  it "renders an accessible hamburger label targeting the future drawer toggle, and the wordmark" do
    render partial: "layouts/navbar"

    expect(rendered).to have_selector("label[for='app-drawer'][aria-label='Open menu']")
    expect(rendered).to have_selector("label svg[aria-hidden='true']")
    expect(rendered).to have_selector("span", text: "Jobdeck")
  end
end
