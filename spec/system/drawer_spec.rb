require "rails_helper"

RSpec.describe "Navigation drawer", type: :system do
  def resize(width, height = 900)
    page.driver.browser.manage.window.resize_to(width, height)
  end

  # Focus moves after daisyUI's .drawer-side visibility transition finishes
  # (or a JS-side fallback timeout), not synchronously on click - poll for it
  # instead of asserting immediately.
  def wait_for_active_element_text(text, timeout: 2)
    Timeout.timeout(timeout) do
      sleep 0.05 until page.evaluate_script("document.activeElement?.textContent?.trim()") == text
    end
  end

  def wait_for_active_element_data_target(value, timeout: 2)
    Timeout.timeout(timeout) do
      sleep 0.05 until page.evaluate_script("document.activeElement?.getAttribute('data-drawer-target')") == value
    end
  end

  context "on a narrow (mobile) viewport, where the drawer is an overlay" do
    before { resize(500) }

    it "opens on hamburger click, moves focus into the panel, and sets aria-expanded" do
      visit customers_path

      hamburger = find("label[data-drawer-target='trigger']", visible: :all)
      expect(hamburger["aria-expanded"]).to eq("false")
      expect(page).not_to have_css("nav[aria-label='Primary'] a", visible: true)

      hamburger.click

      expect(hamburger["aria-expanded"]).to eq("true")
      expect(page).to have_css("nav[aria-label='Primary'] a", visible: true)
      wait_for_active_element_text("Dashboard") # first nav link, since Step 14 added it
      expect(page).to have_css("body.overflow-hidden")
    end

    it "closes on Escape and returns focus to the hamburger" do
      visit customers_path
      hamburger = find("label[data-drawer-target='trigger']", visible: :all)
      hamburger.click
      expect(hamburger["aria-expanded"]).to eq("true")

      find("body").send_keys(:escape)

      expect(hamburger["aria-expanded"]).to eq("false")
      expect(page).to have_css("body:not(.overflow-hidden)")
      wait_for_active_element_data_target("trigger")
    end

    it "closes when the overlay is clicked" do
      visit customers_path
      find("label[data-drawer-target='trigger']", visible: :all).click
      expect(page).to have_css("nav[aria-label='Primary'] a", visible: true)

      find(".drawer-overlay", visible: :all).click

      expect(page).to have_css("label[data-drawer-target='trigger'][aria-expanded='false']", visible: :all)
    end
  end

  context "on a wide (desktop) viewport, where the drawer is a permanent rail" do
    before { resize(1400) }

    it "shows the sidebar without needing the hamburger, which stays hidden" do
      visit customers_path

      expect(page).to have_css("nav[aria-label='Primary'] a", text: "Customers", visible: true)
      expect(page).not_to have_css(".navbar.lg\\:hidden", visible: true)
    end
  end
end
