require "rails_helper"

RSpec.describe "Quotes UI (Step 11 restyle)", type: :system do
  # Row-actions popover, delete-confirm, and failed-submit-focus mechanics are already
  # browser-verified generically in spec/system/customers_ui_spec.rb (Step 8). This spec is
  # about the one genuinely risky part of this step: the R4 responsive rework of the room/
  # line-item editor rows, which quote_form_controller.js manipulates directly by querying
  # data-* attributes - a real click-through is the only way to know it still works.

  let(:lead) { create(:lead) }

  it "adds a room, fills in dimensions, and the area + total area recalculate live" do
    quote = create(:quote, lead: lead, customer: lead.customer)
    visit edit_quote_path(quote)

    click_button "+ Add Room"
    within all("[data-quote-form-target='roomRow']").last do
      fill_in "Room name", with: "Kitchen"
      fill_in "Length", with: "10"
      fill_in "Width", with: "12"
      expect(page).to have_selector("[data-room-area]", text: "120.00")
    end
    expect(find("[data-quote-form-target='totalArea']").text).to eq("120.00")
  end

  it "removing a room hides its row and updates the total area" do
    quote = create(:quote, lead: lead, customer: lead.customer)
    create(:room, quote: quote, length: 10, width: 10) # area 100

    visit edit_quote_path(quote)
    expect(find("[data-quote-form-target='totalArea']").text).to eq("100.0")

    within all("[data-quote-form-target='roomRow']").first do
      find("button[aria-label='Remove room']").click
    end

    expect(page).not_to have_selector("[data-quote-form-target='roomRow']", visible: true)
    expect(find("[data-quote-form-target='totalArea']").text).to eq("0")
  end

  it "adds a line item and its total recalculates from quantity x unit price" do
    quote = create(:quote, lead: lead, customer: lead.customer)
    visit edit_quote_path(quote)

    click_button "+ Add Line Item"
    within all("[data-quote-form-target='lineItemRow']").last do
      fill_in "Quantity", with: "3"
      fill_in "Unit price", with: "5"
      expect(page).to have_selector("[data-line-total]", text: "$15.00")
    end
  end

  it "the estimation tool populates labor/material line items from room area and rates" do
    quote = create(:quote, lead: lead, customer: lead.customer)
    create(:room, quote: quote, length: 10, width: 10) # area 100

    visit edit_quote_path(quote)
    fill_in "Labor Rate ($/sqft)", with: "2"
    fill_in "Material Rate ($/sqft)", with: "3"
    click_button "Populate Line Items"

    rows = all("[data-quote-form-target='lineItemRow']", visible: true)
    expect(rows.size).to eq(2)
    expect(page).to have_field("Description", with: "Labour")
    expect(page).to have_field("Description", with: "Materials")
  end

  it "has no horizontal overflow on the edit form (room/line-item editors) at 375px" do
    quote = create(:quote, :with_line_items, lead: lead, customer: lead.customer)
    create(:room, quote: quote)

    page.driver.browser.manage.window.resize_to(375, 900)
    visit edit_quote_path(quote)

    expect(page).to have_field("Status")
    overflow = page.evaluate_script("document.documentElement.scrollWidth > document.documentElement.clientWidth")
    expect(overflow).to be false
  end

  it "has no horizontal overflow on the show page (rooms + line items tables) at 375px" do
    quote = create(:quote, :with_line_items, lead: lead, customer: lead.customer)
    create(:room, quote: quote)

    page.driver.browser.manage.window.resize_to(375, 900)
    visit quote_path(quote)

    expect(page).to have_content(quote.quote_number)
    overflow = page.evaluate_script("document.documentElement.scrollWidth > document.documentElement.clientWidth")
    expect(overflow).to be false
  end
end
