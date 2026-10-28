require "rails_helper"

# db/seeds.rb is the demo dataset. These specs keep it loading cleanly as the models change, keep
# the dashboard populated on the day it's seeded, and render every page with it, since the seeds
# hold shapes the factories don't (a cancelled job with no dates, an expired quote, attached PDFs).
RSpec.describe "db/seeds.rb", type: :request, skip_authentication: true do
  def load_seeds
    load Rails.root.join("db/seeds.rb")
  end

  # Minitest fixtures can leave committed rows in the shared test DB, and the seeds skip business
  # data when any customer exists. Clear it child-first (so no FK blocks a delete) inside this
  # example's transaction, which rolls it all back afterwards.
  def clear_business_data
    [ LineItem, Order, QuoteLineItem, Room, Quote, Job, Lead, ActivityNote, Document, Customer ].each(&:delete_all)
  end

  # The seeds print a summary line; keep it out of the spec output.
  def quietly
    original, $stdout = $stdout, StringIO.new
    yield
  ensure
    $stdout = original
  end

  def sign_in_seeded(email)
    post session_path, params: { email: email, password: "jobdeck-demo" }
  end

  before do
    clear_business_data
    quietly { load_seeds }
  end

  it "creates one user per role" do
    expect(User.where(email: %w[admin@jobdeck.test pm@jobdeck.test sales@jobdeck.test viewer@jobdeck.test]).pluck(:role))
      .to match_array(%w[admin project_manager sales viewer])
  end

  it "fills every dashboard list, with follow-ups both due today and overdue" do
    expect(Lead.needs_follow_up.where(follow_up_date: Date.current).count).to be >= 1
    expect(Lead.needs_follow_up.where(follow_up_date: ...Date.current).count).to be >= 1
    expect(Job.active_status.where(end_date: ...Date.current).count).to be >= 1
    expect(Order.invoiced_status.where(due_date: ...Date.current).count).to be >= 1
    # By status, not Order.outstanding: the dashboard work splits that scope into to_bill and
    # awaiting_payment, and these seeds need to cover both halves either way.
    expect(Order.where(status: [ :draft, :confirmed ]).count).to be >= 2
    expect(Order.invoiced_status.where(due_date: Date.current..).count).to be >= 1
  end

  it "converts accepted quotes through Lead#convert_to_job!, so each order matches its quote" do
    Quote.accepted_status.find_each do |quote|
      expect(quote.lead).to be_converted_status
      expect(quote.lead.job.orders.order(:id).first.total).to eq(quote.total)
    end
  end

  it "attaches real PDFs" do
    expect(Document.count).to be >= 1
    expect(Document.all.map { |d| d.file.content_type }.uniq).to eq([ "application/pdf" ])
  end

  it "doesn't duplicate anything when run again" do
    expect { quietly { load_seeds } }
      .not_to change { [ User.count, Customer.count, Lead.count, Quote.count, Job.count, Order.count ] }
  end

  it "refuses to seed users in production without SEED_PASSWORD" do
    User.delete_all
    allow(Rails.env).to receive(:production?).and_return(true)
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("SEED_PASSWORD").and_yield

    expect { quietly { load_seeds } }.to raise_error(/SEED_PASSWORD/)
  end

  %w[admin@jobdeck.test viewer@jobdeck.test].each do |email|
    it "renders every page with the seeded data for #{email}" do
      sign_in_seeded(email)
      paths = [ root_path, customers_path, leads_path, jobs_path ] +
              Customer.all.map { customer_path(_1) } +
              Lead.all.map { lead_path(_1) } +
              Quote.all.map { quote_path(_1) } +
              Job.all.map { job_path(_1) } +
              Order.all.map { order_path(_1) }

      paths.each do |path|
        get path
        expect(response).to have_http_status(:ok), "GET #{path} returned #{response.status}"
      end
    end
  end
end
