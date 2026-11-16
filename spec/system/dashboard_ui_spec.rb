require "rails_helper"

RSpec.describe "Dashboard UI (Step 14)", type: :system do
  it "is what the app loads at the root, and its links navigate to the right records" do
    lead = create(:lead, follow_up_date: Date.yesterday, status: :contacted)
    job  = create(:job, status: :active)

    visit root_path
    expect(page).to have_css("h1", text: "Today")

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

    expect(page).to have_css("h1", text: "Today")
    overflow = page.evaluate_script("document.documentElement.scrollWidth > document.documentElement.clientWidth")
    expect(overflow).to be false
  end

  # The cards used to hold 3-4 column tables, which at 1024px pushed the order total off-card
  # behind an inner scroll the page-level check above can't see.
  [ [ 375, 900 ], [ 1024, 768 ], [ 1440, 900 ] ].each do |width, height|
    it "keeps every card's content inside the card at #{width}px, money column included" do
      create(:lead, title: "Bathroom tile — long customer name follow-up", follow_up_date: Date.yesterday, status: :contacted)
      create(:job, title: "Kitchen Renovation — Mitchell Residence, full floor", status: :active)
      order = create(:order, status: :confirmed)

      page.driver.browser.manage.window.resize_to(width, height)
      visit root_path

      expect(page).to have_content(order.order_number)
      clipped = page.evaluate_script(<<~JS)
        [...document.querySelectorAll("#main .card")].some((card) =>
          [...card.querySelectorAll("*")].some((el) => el.scrollWidth > el.clientWidth + 1 && getComputedStyle(el).overflowX !== "visible" && !el.matches(".truncate")))
      JS
      expect(clipped).to be false

      total = page.find("a[href='#{order_path(order)}']")
      card = total.ancestor(".card")
      expect(page.evaluate_script("arguments[0].getBoundingClientRect().right <= arguments[1].getBoundingClientRect().right", total, card)).to be true
    end
  end

  # 1024px is in here on purpose: a half-width card there is as narrow as a phone, which is why
  # the row layout switches on a container query, not a viewport breakpoint.
  [ [ 375, 900 ], [ 1024, 768 ] ].each do |width, height|
    it "at #{width}px, gives the call button a full 44px square apart from the row, and titles the full width" do
    create(:lead, title: "Whole-house engineered hardwood install", follow_up_date: 2.days.ago.to_date, status: :contacted)

    page.driver.browser.manage.window.resize_to(width, height)
    visit root_path

    call = find("a[href^='tel:']", match: :first)
    row_link = call.ancestor("li").find("a:not([href^='tel:'])")
    box = ->(el) { page.evaluate_script("(() => { const r = arguments[0].getBoundingClientRect(); return [r.left, r.right, r.width, r.height]; })()", el) }

    _, _, width, height = box.(call)
    expect([ width, height ]).to all(be >= 44)
    expect(box.(call)[0] - box.(row_link)[1]).to be >= 4

    title = row_link.find("p.font-medium")
    expect(box.(title)[2]).to be >= box.(row_link)[2] - 40 # the title spans the row; nothing sits beside it
    end
  end

  it "reschedules a follow-up from its row without leaving the page" do
    ActiveRecord::Base.connection.disable_referential_integrity { Lead.update_all(follow_up_date: nil) }
    keep  = create(:lead, title: "Basement LVT", follow_up_date: Date.current, status: :contacted)
    moved = create(:lead, title: "Lobby tile", follow_up_date: Date.current, status: :contacted)
    new_date = Date.current + 5

    visit root_path
    expect(page).to have_css("#due_today_count", text: "2")

    find("button[aria-label='Reschedule follow-up for #{moved.customer.full_name}']").click
    find("#reschedule-#{ActionView::RecordIdentifier.dom_id(moved)}-date", visible: true).set(new_date)
    click_button "Reschedule"

    expect(page).not_to have_link("Lobby tile")
    expect(page).to have_link(keep.title)
    expect(page).to have_css("#due_today_count", text: "1")
    expect(page).to have_current_path(root_path)
    expect(moved.reload.follow_up_date).to eq(new_date)
  end

  it "shows the empty state once the last overdue follow-up is rescheduled" do
    ActiveRecord::Base.connection.disable_referential_integrity { Lead.update_all(follow_up_date: nil) }
    lead = create(:lead, follow_up_date: Date.current - 3, status: :contacted)

    visit root_path
    find("button[aria-label='Reschedule follow-up for #{lead.customer.full_name}']").click
    click_button "Reschedule"

    expect(page).to have_content("No overdue follow-ups.")
    expect(page).to have_css("#overdue_count", text: "0")
    expect(lead.reload.follow_up_date).to eq(Date.current.tomorrow)
  end

  it "at 375px, gives the reschedule button a full 44px square and keeps its popover on screen" do
    create(:lead, title: "Whole-house engineered hardwood install", follow_up_date: 2.days.ago.to_date, status: :contacted)

    page.driver.browser.manage.window.resize_to(375, 900)
    visit root_path

    button = find("button[aria-label^='Reschedule follow-up for']", match: :first)
    rect = ->(el) { page.evaluate_script("(() => { const r = arguments[0].getBoundingClientRect(); return [r.left, r.right, r.width, r.height]; })()", el) }
    expect(rect.(button)[2..3]).to all(be >= 44)

    button.click
    popover = find("[popover]:popover-open", visible: true)
    left, right, = rect.(popover)
    expect(left).to be >= 0
    expect(right).to be <= page.evaluate_script("document.documentElement.clientWidth")
  end
end
