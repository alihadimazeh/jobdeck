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
    waiting  = page.at_xpath("//div[contains(@class,'card')][.//h2[text()='Waiting on Payment']]").text
    to_bill  = page.at_xpath("//div[contains(@class,'card')][.//h2[text()='Not Yet Billed']]").text

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

    expect(response.body).to include("Nothing needs follow-up.")
    expect(response.body).to include("No active jobs.")
    expect(response.body).to include("Nothing waiting on payment.")
    expect(response.body).to include("Nothing to bill.")
  end

  it "shows the true total count even when the preview list is capped" do
    ActiveRecord::Base.connection.disable_referential_integrity { Job.delete_all }
    create_list(:job, DashboardController::PREVIEW_LIMIT + 2, status: :active)

    get root_path

    expect(response.body).to match(/stat-value[^"]*">\s*#{DashboardController::PREVIEW_LIMIT + 2}\s*</)
  end
end
