require "rails_helper"

RSpec.describe "shared/_row_actions", type: :view do
  before do
    render partial: "shared/row_actions", locals: {
      edit_path: "/customers/1/edit",
      delete_path: "/customers/1",
      delete_confirm: "Are you sure?",
      label: "Ada Lovelace",
      id: "customer_1"
    }
  end

  it "renders a trigger button anchored to a Popover-API menu, with an accessible name" do
    expect(rendered).to have_selector(
      "button[popovertarget='row-actions-customer_1'][aria-label='Actions for Ada Lovelace']"
    )
    expect(rendered).to have_selector("button svg[aria-hidden='true']")
  end

  it "renders the menu as the trigger's popover target, anchored to it" do
    expect(rendered).to have_selector("ul[popover]#row-actions-customer_1.dropdown.menu")
    expect(rendered).to match(/anchor-name:\s*--row-actions-customer_1/)
    expect(rendered).to match(/position-anchor:\s*--row-actions-customer_1/)
  end

  it "renders Edit as a link and Delete as a confirmed button_to" do
    expect(rendered).to have_selector("li a[href='/customers/1/edit']", text: "Edit")
    expect(rendered).to have_selector(
      "li form[action='/customers/1'] input[name='_method'][value='delete']", visible: false
    )
    expect(rendered).to have_selector("li form[data-turbo-confirm='Are you sure?']", visible: false)
    expect(rendered).to have_selector("li form button", text: "Delete")
  end
end
