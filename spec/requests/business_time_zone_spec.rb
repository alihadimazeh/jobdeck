require "rails_helper"

# "Today" is the business's day (config.time_zone), not UTC. 10:30pm Eastern on Oct 24 is
# already Oct 25 in UTC - before the zone was set, the dashboard showed tomorrow's date and
# counted today's calls as a day late from 8pm on.
RSpec.describe "Business time zone", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  around do |example|
    travel_to(Time.find_zone!("Eastern Time (US & Canada)").local(2026, 10, 24, 22, 30)) { example.run }
  end

  it "runs the app on Eastern time" do
    expect(Time.zone.name).to eq("Eastern Time (US & Canada)")
    expect(Date.current).to eq(Date.new(2026, 10, 24))
  end

  it "keeps the dashboard on the local day late in the evening" do
    ActiveRecord::Base.connection.disable_referential_integrity { Lead.delete_all }
    today = create(:lead, title: "Call back about the ensuite", follow_up_date: Date.new(2026, 10, 24), status: :contacted)
    yesterday = create(:lead, title: "Basement LVP quote", follow_up_date: Date.new(2026, 10, 23), status: :contacted)

    get root_path
    page = Nokogiri::HTML(response.body)
    due_today = page.at_xpath("//div[contains(@class,'card')][.//h2[contains(., 'Due Today')]]").text
    overdue   = page.at_xpath("//div[contains(@class,'card')][.//h2[contains(., 'Overdue')]]").text.squish

    expect(page.at_css("h1 time")["datetime"]).to eq("2026-10-24")
    expect(due_today).to include(today.title)
    expect(overdue).to include(yesterday.title, "1 day late")
    expect(overdue).not_to include(today.title)
  end
end
