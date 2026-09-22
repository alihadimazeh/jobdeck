require "rails_helper"

# Keyboard focus in the dynamic room/line-item editors: a new row lands before the
# "+ Add" button in DOM order, and removing a row hides the button that had focus.
#
# skip_authentication + an inline sign-in: works both before and after the global system
# sign-in hook (PR #62) lands, without signing in twice.
RSpec.describe "Estimation tool row focus", type: :system, skip_authentication: true do
  let(:customer) { create(:customer) }
  let(:lead)     { create(:lead, customer: customer) }
  let(:user)     { create(:user) }

  before do
    visit new_session_path
    fill_in "Email", with: user.email
    fill_in "Password", with: user.password
    click_button "Sign in"
    expect(page).to have_current_path(root_path)
  end

  def focused_name
    page.evaluate_script("document.activeElement.name || document.activeElement.textContent.trim()")
  end

  it "moves focus into a newly added room, and to a neighbouring row after removal" do
    visit new_lead_quote_path(lead)
    click_button "+ Add Room"
    expect(focused_name).to match(/\[rooms_attributes\]\[\d+\]\[name\]\z/)
    added = focused_name

    within(all("[data-quote-form-target~='roomRow']").last) { click_button "Remove" }
    expect(focused_name).to match(/\[rooms_attributes\]\[0\]\[name\]\z/)
    expect(focused_name).not_to eq(added)
    expect(page).to have_css("[data-quote-form-target='status']", text: "Room removed", visible: :all)
  end

  it "falls back to the + Add button when the last visible row is removed" do
    visit new_lead_quote_path(lead)
    within(first("[data-quote-form-target~='roomRow']")) { click_button "Remove" }
    expect(focused_name).to eq("+ Add Room")
  end

  it "moves focus into a new order line item" do
    job = create(:job, customer: customer)
    visit new_job_order_path(job)
    click_button "+ Add Line Item"
    expect(focused_name).to match(/\[line_items_attributes\]\[\d+\]\[item_type\]\z/)
    expect(page).to have_css("[data-order-form-target='status']", text: "Line item added", visible: :all)
  end
end
