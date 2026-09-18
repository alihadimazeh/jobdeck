require "rails_helper"

RSpec.describe "shared/_badge", type: :view do
  it "renders the label inside a daisyUI badge with the given variant" do
    render partial: "shared/badge", locals: { label: "Active", variant: :success }
    expect(rendered).to have_selector("span.badge.badge-soft.badge-success", text: "Active")
  end
end
