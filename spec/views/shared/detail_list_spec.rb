require "rails_helper"

RSpec.describe "shared/_detail_list", type: :view do
  it "renders a label/value pair per item" do
    render partial: "shared/detail_list", locals: { items: [ [ "Phone", "555-0100" ], [ "Email", nil ] ] }
    expect(rendered).to have_selector("dt", text: "Phone")
    expect(rendered).to have_selector("dd", text: "555-0100")
  end

  it "falls back to an em-dash for a blank value" do
    render partial: "shared/detail_list", locals: { items: [ [ "Email", nil ] ] }
    expect(rendered).to have_selector("dd", text: "—")
  end

  it "defaults to a 2-column grid" do
    render partial: "shared/detail_list", locals: { items: [ [ "A", "1" ] ] }
    expect(rendered).to have_selector("dl.sm\\:grid-cols-2")
  end
end
