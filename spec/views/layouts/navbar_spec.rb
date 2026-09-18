require "rails_helper"

RSpec.describe "layouts/_navbar", type: :view do
  it "renders a keyboard-focusable, accessible hamburger targeting the drawer toggle, and the wordmark" do
    render partial: "layouts/navbar"

    expect(rendered).to have_selector(
      "label[for='app-drawer'][role='button'][tabindex='0']" \
      "[aria-label='Open menu'][aria-expanded='false'][data-drawer-target='trigger']"
    )
    expect(rendered).to have_selector("label svg[aria-hidden='true']")
    expect(rendered).to have_selector("span", text: "Jobdeck")
  end
end
