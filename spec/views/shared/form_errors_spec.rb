require "rails_helper"

RSpec.describe "shared/_form_errors", type: :view do
  it "renders nothing when the model has no errors" do
    customer = build(:customer)
    render partial: "shared/form_errors", locals: { model: customer }
    expect(rendered.strip).to be_empty
  end

  it "renders a focus-managed, linked error summary when the model is invalid" do
    customer = build(:customer, first_name: nil)
    customer.valid?

    render partial: "shared/form_errors", locals: { model: customer }

    expect(rendered).to have_selector(
      "div#form-errors[role='alert'][tabindex='-1'][data-controller='autofocus']"
    )
    expect(rendered).to have_selector("a[href='#customer_first_name']")
  end
end
