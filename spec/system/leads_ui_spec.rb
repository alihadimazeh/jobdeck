require "rails_helper"

RSpec.describe "Leads UI (Step 9 restyle)", type: :system do
  # The row-actions popover, delete-confirm, and failed-submit-focus mechanics are already
  # browser-verified generically in spec/system/customers_ui_spec.rb (Step 8) - this spec
  # only covers what's actually different about Leads.

  it "opens the row-actions popover on click, same as Customers" do
    lead = create(:lead)
    visit leads_path

    find("button[aria-label='Actions for #{lead.title}']").click
    expect(page).to have_link("Edit", href: edit_lead_path(lead), visible: true)
  end

  it "navigates to the quote form via the Quotes card's Create Quote action" do
    lead = create(:lead)
    visit lead_path(lead)

    click_link "Create Quote"
    expect(page).to have_current_path(new_lead_quote_path(lead))
  end

  it "has no horizontal overflow on the show page (detail list + job + quotes cards) at 375px" do
    lead = create(:lead)
    create(:job, :from_lead, lead: lead, customer: lead.customer)
    create(:quote, lead: lead, customer: lead.customer)

    page.driver.browser.manage.window.resize_to(375, 900)
    visit lead_path(lead)

    expect(page).to have_content(lead.title)
    overflow = page.evaluate_script("document.documentElement.scrollWidth > document.documentElement.clientWidth")
    expect(overflow).to be false
  end
end
