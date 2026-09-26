require "rails_helper"

RSpec.describe "shared/_form_container", type: :view do
  it "defaults to max-w-2xl and yields the block content" do
    render "shared/form_container" do
      "<p>form goes here</p>".html_safe
    end
    expect(rendered).to have_selector("div.max-w-2xl p", text: "form goes here")
  end

  it "uses max-w-3xl when width: :lg" do
    render "shared/form_container", { width: :lg } do
      "content".html_safe
    end
    expect(rendered).to have_selector("div.max-w-3xl")
  end

  it "explains the required-field marker" do
    render "shared/form_container" do
      "content".html_safe
    end
    expect(rendered).to have_text("Fields marked * are required.")
  end
end
