require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  it "is the root path" do
    get root_path
    expect(response).to have_http_status(:success)
  end

  it "counts and lists leads needing follow-up, excluding converted/lost and future dates" do
    due    = create(:lead, follow_up_date: Date.yesterday, status: :contacted)
    future = create(:lead, follow_up_date: Date.tomorrow, status: :contacted)
    lost   = create(:lead, follow_up_date: Date.yesterday, status: :lost)
    none   = create(:lead, follow_up_date: nil, status: :new)

    get root_path

    expect(response.body).to include(due.title)
    expect(response.body).not_to include(future.title)
    expect(response.body).not_to include(lost.title)
    expect(response.body).not_to include(none.title)
  end

  it "counts and lists active jobs, excluding on_hold/completed/cancelled" do
    active    = create(:job, status: :active)
    completed = create(:job, status: :completed)

    get root_path

    expect(response.body).to include(active.title)
    expect(response.body).not_to include(completed.title)
  end

  it "splits orders into waiting on payment (invoiced) and not yet billed (draft/confirmed), excluding paid" do
    ActiveRecord::Base.connection.disable_referential_integrity { LineItem.delete_all; Order.delete_all }
    invoiced  = create(:order, status: :invoiced)
    confirmed = create(:order, status: :confirmed)
    paid      = create(:order, status: :paid)
    invoiced.update_columns(total: 1_200)
    confirmed.update_columns(total: 300)

    get root_path
    page = Nokogiri::HTML(response.body)
    waiting  = page.at_xpath("//div[contains(@class,'card')][.//h2[contains(., 'Waiting on Payment')]]").text
    to_bill  = page.at_xpath("//div[contains(@class,'card')][.//h2[contains(., 'Not Yet Billed')]]").text

    expect(waiting).to include(invoiced.order_number, "$1,200.00")
    expect(waiting).not_to include(confirmed.order_number)
    expect(to_bill).to include(confirmed.order_number, "$300.00")
    expect(to_bill).not_to include(invoiced.order_number)
    expect(response.body).not_to include(paid.order_number)
  end

  it "flags an overdue invoice by how many days late it is, and shows the due date otherwise" do
    late   = create(:order, status: :invoiced, due_date: 9.days.ago.to_date)
    on_time = create(:order, status: :invoiced, due_date: Date.new(2099, 1, 15))

    get root_path

    expect(response.body).to include("9 days overdue")
    expect(response.body).to include("Due Jan 15, 2099")
    expect(response.body.index(late.order_number)).to be < response.body.index(on_time.order_number)
  end

  it "renders empty states when nothing qualifies for a section" do
    # test/fixtures/*.yml rows can be sitting in the shared test DB from a Minitest run
    # (RSpec's per-example rollback doesn't touch data already committed before its
    # transaction started - see spec/requests/customers_spec.rb's empty-state test for the
    # same issue) - clear explicitly so none of them accidentally qualify.
    ActiveRecord::Base.connection.disable_referential_integrity do
      LineItem.delete_all
      Order.delete_all
      Job.delete_all
      QuoteLineItem.delete_all
      Room.delete_all
      Quote.delete_all
      Lead.delete_all
    end

    get root_path

    expect(response.body).to include("No follow-ups due today.")
    expect(response.body).to include("No overdue follow-ups.")
    expect(response.body).to include("No active jobs.")
    expect(response.body).to include("Nothing waiting on payment.")
    expect(response.body).to include("Nothing to bill.")
  end

  it "shows the true total count even when the preview list is capped" do
    # Orders go too: one left pointing at a deleted job would break its row's job title.
    ActiveRecord::Base.connection.disable_referential_integrity { LineItem.delete_all; Order.delete_all; Job.delete_all }
    create_list(:job, DashboardController::PREVIEW_LIMIT + 2, status: :active)

    get root_path

    count = Nokogiri::HTML(response.body).at_xpath("//h2[contains(., 'Active Jobs')]/span").text.strip
    expect(count).to eq((DashboardController::PREVIEW_LIMIT + 2).to_s)
  end

  it "gives each follow-up a tap-to-call link and says how late it is" do
    customer = create(:customer, first_name: "Sarah", last_name: "Mitchell", phone: "(905) 555-0142")
    create(:lead, customer: customer, follow_up_date: 3.days.ago.to_date, status: :contacted)
    create(:lead, follow_up_date: Date.current, status: :contacted)

    get root_path

    expect(response.body).to include('href="tel:9055550142"')
    expect(response.body).to include('aria-label="Call Sarah Mitchell, (905) 555-0142"')
    expect(response.body).to include("3 days late")
  end

  it "shows each active job's site address, not the customer's billing address" do
    job = create(:job, status: :active, address_line_1: "48 Birch Lane", city: "Hamilton")

    get root_path

    expect(response.body).to include("48 Birch Lane, Hamilton · #{job.customer.full_name}")
  end

  it "keeps today's follow-ups visible however many overdue ones pile up" do
    ActiveRecord::Base.connection.disable_referential_integrity { Lead.delete_all }
    create_list(:lead, DashboardController::PREVIEW_LIMIT + 1, follow_up_date: 10.days.ago.to_date, status: :contacted)
    today = create(:lead, title: "Call back about the ensuite", follow_up_date: Date.current, status: :contacted)

    get root_path
    page = Nokogiri::HTML(response.body)
    due_today = page.at_xpath("//div[contains(@class,'card')][.//h2[contains(., 'Due Today')]]").text
    overdue   = page.at_xpath("//div[contains(@class,'card')][.//h2[contains(., 'Overdue')]]")

    expect(due_today).to include(today.title)
    expect(overdue.text).not_to include(today.title)
    expect(overdue.at_xpath(".//h2/span").text.strip).to eq((DashboardController::PREVIEW_LIMIT + 1).to_s)
  end

  it "points each 'View all' at the card's own filter, using integer enum values" do
    get root_path
    links = Nokogiri::HTML(response.body).css("a").map { |a| [ a["aria-label"], CGI.unescape(a["href"].to_s) ] }.to_h
    closed = Lead.statuses.values_at("converted", "lost")

    expect(links["View all follow-ups due today"]).to include("q[follow_up_date_eq]=#{Date.current.iso8601}")
    expect(links["View all overdue follow-ups"]).to include("q[follow_up_date_lt]=#{Date.current.iso8601}", "q[s]=follow_up_date asc")
    closed.each { |value| expect(links["View all overdue follow-ups"]).to include("q[status_not_in][]=#{value}") }
    expect(links["View all active jobs"]).to include("q[status_eq]=#{Job.statuses["active"]}", "q[s][]=end_date asc", "q[s][]=start_date asc")
  end

  it "is titled Today with the date" do
    get root_path

    h1 = Nokogiri::HTML(response.body).at_css("h1")
    expect(h1.text.squish).to start_with("Today")
    expect(h1.at_css("time")["datetime"]).to eq(Date.current.iso8601)
  end

  it "labels each active job's date: days over, else the end date, else the start date, plus the crew" do
    over     = create(:job, title: "Lobby LVT", status: :active, end_date: 4.days.ago.to_date, assigned_to: "Mike's crew")
    ending   = create(:job, title: "Ensuite tile", status: :active, start_date: Date.new(2026, 1, 5), end_date: Date.new(2099, 3, 2))
    starting = create(:job, title: "Basement LVP", status: :active, start_date: Date.new(2099, 6, 1), end_date: nil)

    get root_path
    rows = Nokogiri::HTML(response.body).css("li").map(&:text).map(&:squish)

    expect(rows.find { |r| r.include?(over.title) }).to include("4 days over", "Crew: Mike's crew")
    expect(rows.find { |r| r.include?(ending.title) }).to include("Ends Mar 02, 2099")
    expect(rows.find { |r| r.include?(starting.title) }).to include("Starts Jun 01, 2099")
  end

  it "titles money rows by job, and labels the header totals only when the card has rows" do
    ActiveRecord::Base.connection.disable_referential_integrity { LineItem.delete_all; Order.delete_all }
    job = create(:job, title: "Gonzalez kitchen backsplash")
    order = create(:order, job: job, status: :invoiced)
    order.update_columns(total: 2_500)

    get root_path
    page = Nokogiri::HTML(response.body)
    waiting = page.at_xpath("//div[contains(@class,'card')][.//h2[contains(., 'Waiting on Payment')]]")
    to_bill = page.at_xpath("//div[contains(@class,'card')][.//h2[contains(., 'Not Yet Billed')]]")

    expect(waiting.at_css("li p.font-medium").text).to eq(job.title)
    expect(waiting.text.squish).to include("#{order.customer.full_name} · #{order.order_number}", "$2,500.00 owed")
    expect(to_bill.text).not_to match(/\$[\d,.]+ to bill/)
    expect(to_bill.text).not_to include("$0.00")
  end

  it "keeps an over-running job in the 5-row preview however many jobs started earlier" do
    ActiveRecord::Base.connection.disable_referential_integrity { LineItem.delete_all; Order.delete_all; Job.delete_all }
    DashboardController::PREVIEW_LIMIT.times do |i|
      create(:job, status: :active, start_date: (60 - i).days.ago.to_date, end_date: (10 + i).days.from_now.to_date)
    end
    over = create(:job, title: "Basement rec room LVP", status: :active, start_date: 3.days.ago.to_date, end_date: 5.days.ago.to_date)

    get root_path
    rows = Nokogiri::HTML(response.body).xpath("//div[contains(@class,'card')][.//h2[contains(., 'Active Jobs')]]//li").map { |li| li.text.squish }

    expect(rows.first).to include(over.title, "5 days over")
  end
end
