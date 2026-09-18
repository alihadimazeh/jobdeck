require "rails_helper"

RSpec.describe "Dashboard UI (Step 14)", type: :system do
  it "is what the app loads at the root, and its links navigate to the right records" do
    lead = create(:lead, follow_up_date: Date.yesterday, status: :contacted)
    job  = create(:job, status: :active)

    visit root_path
    expect(page).to have_content("Dashboard")

    click_link lead.title
    expect(page).to have_current_path(lead_path(lead))

    visit root_path
    click_link job.title
    expect(page).to have_current_path(job_path(job))
  end

  it "has no horizontal overflow at 375px" do
    create(:lead, follow_up_date: Date.yesterday, status: :contacted)
    create(:job, status: :active)
    create(:order, status: :confirmed)

    page.driver.browser.manage.window.resize_to(375, 900)
    visit root_path

    expect(page).to have_content("Dashboard")
    overflow = page.evaluate_script("document.documentElement.scrollWidth > document.documentElement.clientWidth")
    expect(overflow).to be false
  end
end
