require "rails_helper"

RSpec.describe "Jobs UI (Step 10 restyle)", type: :system do
  # Row-actions popover, delete-confirm, and failed-submit-focus mechanics are already
  # browser-verified generically in spec/system/customers_ui_spec.rb (Step 8) - this only
  # covers what's actually new for Jobs.

  it "navigates to the order form via the Orders card's New Order action" do
    job = create(:job)
    visit job_path(job)

    click_link "New Order"
    expect(page).to have_current_path(new_job_order_path(job))
  end

  it "navigates to the originating lead when the job came from one" do
    job = create(:job, :from_lead)
    visit job_path(job)

    click_link job.lead.title
    expect(page).to have_current_path(lead_path(job.lead))
  end

  it "has no horizontal overflow on the show page (detail list + lead + orders cards) at 375px" do
    job = create(:job, :from_lead, address_line_1: "1 Main St", city: "Ottawa")
    create(:order, job: job, customer: job.customer)

    page.driver.browser.manage.window.resize_to(375, 900)
    visit job_path(job)

    expect(page).to have_content(job.title)
    overflow = page.evaluate_script("document.documentElement.scrollWidth > document.documentElement.clientWidth")
    expect(overflow).to be false
  end
end
