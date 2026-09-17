require "rails_helper"

RSpec.describe "Customers UI (Step 8 restyle)", type: :system do
  def resize(width, height = 900)
    page.driver.browser.manage.window.resize_to(width, height)
  end

  def wait_for_active_element_id(id, timeout: 2)
    Timeout.timeout(timeout) do
      sleep 0.05 until page.evaluate_script("document.activeElement?.id") == id
    end
  end

  it "opens the row-actions popover on click and navigates via its Edit link" do
    customer = create(:customer)
    visit customers_path

    expect(page).not_to have_link("Edit", href: edit_customer_path(customer))

    find("button[aria-label='Actions for #{customer.full_name}']").click
    expect(page).to have_link("Edit", href: edit_customer_path(customer), visible: true)

    click_link "Edit", href: edit_customer_path(customer)
    expect(page).to have_current_path(edit_customer_path(customer))
  end

  it "confirms before deleting from the row-actions menu, and cancelling leaves the row intact" do
    customer = create(:customer)
    visit customers_path

    find("button[aria-label='Actions for #{customer.full_name}']").click
    dismiss_confirm do
      click_button "Delete"
    end

    expect(page).to have_content(customer.full_name)
    expect(Customer.exists?(customer.id)).to be true
  end

  it "moves keyboard focus to the error summary on a failed submit, linked to the invalid field" do
    visit new_customer_path
    click_button "Create Customer"

    expect(page).to have_css("#form-errors[role='alert']")
    expect(page.evaluate_script("document.activeElement.id")).to eq("form-errors")

    find("#form-errors a", text: "First name can't be blank").click
    wait_for_active_element_id("customer_first_name")
  end

  it "has no horizontal overflow on the index page at a narrow (375px) viewport" do
    create(:customer)
    resize(375, 800)
    visit customers_path

    expect(page).to have_content("Customers")
    overflow = page.evaluate_script("document.documentElement.scrollWidth > document.documentElement.clientWidth")
    expect(overflow).to be false
  end
end
