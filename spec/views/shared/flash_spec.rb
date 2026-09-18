require "rails_helper"

RSpec.describe "shared/_flash", type: :view do
  it "renders a success alert for a notice" do
    allow(view).to receive(:flash).and_return({ notice: "Saved successfully" })
    render partial: "shared/flash"
    expect(rendered).to have_selector("div[aria-live='polite'] div.alert.alert-success", text: "Saved successfully")
    expect(rendered).not_to have_selector("[role='alert']")
  end

  it "renders an error alert with role=alert for an alert-type flash" do
    allow(view).to receive(:flash).and_return({ alert: "Something went wrong" })
    render partial: "shared/flash"
    expect(rendered).to have_selector("div.alert.alert-error[role='alert']", text: "Something went wrong")
  end

  it "renders nothing when there is no flash" do
    allow(view).to receive(:flash).and_return({})
    render partial: "shared/flash"
    expect(rendered).not_to have_selector(".alert")
  end

  it "skips a blank message" do
    allow(view).to receive(:flash).and_return({ notice: "" })
    render partial: "shared/flash"
    expect(rendered).not_to have_selector(".alert")
  end
end
