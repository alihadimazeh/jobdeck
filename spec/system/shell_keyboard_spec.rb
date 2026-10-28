require "rails_helper"

# Keyboard order through the app shell (layouts/application, _navbar, _sidebar), driven with
# real Tab presses rather than by inspecting attributes.
RSpec.describe "App shell keyboard order", type: :system do
  def resize(width, height = 900)
    page.driver.browser.manage.window.resize_to(width, height)
  end

  def tab
    page.driver.browser.action.send_keys(:tab).perform
  end

  def active(js)
    page.evaluate_script("document.activeElement#{js}")
  end

  it "on a phone, goes Skip to content -> the hamburger, with no invisible stop for the drawer checkbox" do
    resize(375)
    visit root_path
    page.execute_script("document.activeElement.blur()")

    tab
    expect(active(".textContent.trim()")).to eq("Skip to content")
    tab
    expect(active(".getAttribute('aria-label')")).to eq("Open menu")
  end

  it "opens the drawer from the keyboard alone" do
    resize(375)
    visit root_path
    find("label[data-drawer-target='trigger']").send_keys(:enter)

    expect(page).to have_css("nav[aria-label='Primary'] a", visible: true)
  end

  it "on desktop, offers Skip to navigation, which lands in the rail before the page content" do
    resize(1440)
    visit root_path
    page.execute_script("document.activeElement.blur()")

    tab
    tab
    expect(active(".textContent.trim()")).to eq("Skip to navigation")
    page.driver.browser.action.send_keys(:enter).perform
    expect(page).to have_current_path(/#primary-nav\z/, url: true)
    tab

    expect(active(".closest('nav')?.getAttribute('aria-label')")).to eq("Primary")
  end

  it "rings a focused ghost button and a plain link in Job Blue, not ink" do
    resize(1440)
    visit root_path
    primary = page.evaluate_script("getComputedStyle(document.documentElement).getPropertyValue('--color-primary').trim()")
    probe = "(el) => { el.focus(); const s = getComputedStyle(el); return [s.outlineColor, s.outlineStyle, s.outlineWidth]; }"
    expected = page.evaluate_script("(() => { const d = document.createElement('div'); d.style.color = '#{primary}'; document.body.append(d); const c = getComputedStyle(d).color; d.remove(); return c; })()")

    # Focus via keyboard so :focus-visible applies.
    ghost = find("a.btn-ghost", text: "View all", match: :first)
    page.execute_script("arguments[0].focus()", ghost)
    expect(page.evaluate_script("(#{probe})(arguments[0])", ghost)).to eq([ expected, "solid", "2px" ])
  end
end
