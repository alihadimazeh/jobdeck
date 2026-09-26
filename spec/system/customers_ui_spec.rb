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

    # TEMP DEBUG (draft PR #82): record what happens around the popover click on CI.
    page.execute_script(<<~JS)
      window.__dbg = [];
      const log = (m) => window.__dbg.push(Math.round(performance.now()) + "ms " + m);
      log("readyState=" + document.readyState);
      document.addEventListener("beforetoggle", e => log("beforetoggle " + e.target.id + " " + e.oldState + "->" + e.newState), true);
      document.addEventListener("toggle", e => log("toggle " + e.target.id + " " + e.newState), true);
      ["pointerdown", "click"].forEach(t => document.addEventListener(t, e => log(t + " on " + (e.target.closest("button,a,label,input")?.outerHTML || e.target.tagName).slice(0, 120)), true));
      ["turbo:load", "turbo:visit", "turbo:before-render", "turbo:render", "turbo:before-cache"].forEach(t => document.addEventListener(t, () => log(t), true));
    JS
    trigger = find("button[aria-label='Actions for #{customer.full_name}']")
    puts "[DBG] trigger rect=#{page.evaluate_script("JSON.stringify(arguments[0].getBoundingClientRect())", trigger)}"
    trigger.click
    sleep 1
    puts "[DBG] events=#{page.evaluate_script('window.__dbg').inspect}"
    puts "[DBG] popover open? #{page.evaluate_script("document.getElementById('row-actions-#{ActionView::RecordIdentifier.dom_id(customer)}').matches(':popover-open')")}"
    puts "[DBG] active=#{page.evaluate_script('document.activeElement?.outerHTML?.slice(0,120)')}"
    puts "[DBG] elementFromPoint at trigger=#{page.evaluate_script("(() => { const r = arguments[0].getBoundingClientRect(); return document.elementFromPoint(r.x + r.width/2, r.y + r.height/2)?.outerHTML?.slice(0,120) })()", trigger)}"
    puts "[DBG] url=#{page.current_url} window=#{page.driver.browser.manage.window.size.to_a.inspect} inner=#{page.evaluate_script('[innerWidth, innerHeight]').inspect}"
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
