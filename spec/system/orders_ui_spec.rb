require "rails_helper"

RSpec.describe "Orders UI (Step 12 restyle)", type: :system do
  # Row-actions popover, delete-confirm, and failed-submit-focus mechanics are already
  # browser-verified generically in spec/system/customers_ui_spec.rb (Step 8). This spec
  # covers the R4 responsive rework of the line-item editor rows against
  # order_form_controller.js - the same risk as Step 11's Quotes spec, simpler here since
  # there's no rooms/estimation tool.

  let(:job) { create(:job) }

  it "adds a line item and its total recalculates from quantity x unit price" do
    order = create(:order, job: job, customer: job.customer)
    visit edit_order_path(order)

    click_button "+ Add Line Item"
    within all("[data-order-form-target='lineItemRow']").last do
      fill_in "Quantity", with: "4"
      fill_in "Unit price", with: "2.5"
      expect(page).to have_selector("[data-line-total]", text: "$10.00")
    end
  end

  it "removing a line item hides its row" do
    order = create(:order, job: job, customer: job.customer)
    create(:line_item, order: order)

    visit edit_order_path(order)
    expect(page).to have_selector("[data-order-form-target='lineItemRow']", visible: true, count: 1)

    find("button[aria-label='Remove line item']").click

    expect(page).not_to have_selector("[data-order-form-target='lineItemRow']", visible: true)
  end

  it "has no horizontal overflow on the edit form or show page at 375px" do
    order = create(:order, job: job, customer: job.customer)
    create(:line_item, order: order)

    page.driver.browser.manage.window.resize_to(375, 900)

    visit edit_order_path(order)
    expect(page).to have_field("Status")
    expect(page.evaluate_script("document.documentElement.scrollWidth > document.documentElement.clientWidth")).to be false

    visit order_path(order)
    expect(page).to have_content(order.order_number)
    expect(page.evaluate_script("document.documentElement.scrollWidth > document.documentElement.clientWidth")).to be false
  end
end
