require "rails_helper"

RSpec.describe "shared/_card", type: :view do
  it "renders just the body when no title or actions are given" do
    render "shared/card" do
      "<p>body</p>".html_safe
    end
    expect(rendered).to have_selector("div.card div.card-body p", text: "body")
    expect(rendered).not_to have_selector("h2")
  end

  it "renders a header row with the title when given" do
    render "shared/card", { title: "Rooms" } do
      "content".html_safe
    end
    expect(rendered).to have_selector("h2", text: "Rooms")
  end

  it "renders the actions slot in the header" do
    render "shared/card", { title: "Quotes", actions: "<a href='/x'>Create</a>".html_safe } do
      "content".html_safe
    end
    expect(rendered).to have_selector("div.card > div a", text: "Create")
  end
end
