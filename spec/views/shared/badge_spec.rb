require "rails_helper"

RSpec.describe "shared/_badge", type: :view do
  it "renders the label inside a daisyUI badge with the given variant" do
    render partial: "shared/badge", locals: { label: "Active", variant: :success }
    expect(rendered).to have_selector("span.badge.badge-soft.badge-success", text: "Active")
  end

  it "never wraps a multi-word label onto two lines" do
    render partial: "shared/badge", locals: { label: "On hold", variant: :warning }
    expect(rendered).to have_selector("span.badge.whitespace-nowrap", text: "On hold")
  end
end
