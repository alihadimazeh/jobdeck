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

  it "on a 360px phone, keeps the follow-up column on screen when arriving from a dashboard follow-up card" do
    create(:lead, title: "Condo hallway carpet tile", follow_up_date: 30.days.ago.to_date, status: :contacted)
    create(:lead, title: "Whole-house engineered hardwood install", follow_up_date: 120.days.ago.to_date, status: :contacted)

    # 360px, not 375: the narrowest common Android width, where a few px of padding decide it.
    page.driver.browser.manage.window.resize_to(360, 812)
    visit leads_path(q: { follow_up_date_lt: Date.current.iso8601, status_not_in: Lead.statuses.values_at("converted", "lost") })

    late = find("td", text: "30 days late")
    call = late.find("a[href^='tel:']")
    expect(page.evaluate_script("arguments[0].getBoundingClientRect().right <= window.innerWidth", call)).to be true
    size = page.evaluate_script("(() => { const r = arguments[0].getBoundingClientRect(); return [r.width, r.height]; })()", call)
    expect(size).to all(be >= 44)
    scrolls = page.evaluate_script("[...document.querySelectorAll('#main .overflow-x-auto')].some((el) => el.scrollWidth > el.clientWidth + 1)")
    expect(scrolls).to be false
  end
end
