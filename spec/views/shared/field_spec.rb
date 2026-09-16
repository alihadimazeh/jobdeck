require "rails_helper"

RSpec.describe "shared/_field", type: :view do
  let(:customer) { build(:customer) }
  let(:form) { ActionView::Helpers::FormBuilder.new(:customer, customer, view, {}) }

  it "renders a labeled text input by default" do
    render partial: "shared/field", locals: { form: form, attr: :first_name }
    expect(rendered).to have_selector("label.label", text: "First name")
    expect(rendered).to have_selector("input.input.w-full#customer_first_name[type='text']")
  end

  it "humanizes a custom label when none is given, and accepts an override" do
    render partial: "shared/field", locals: { form: form, attr: :first_name, label: "Given name" }
    expect(rendered).to have_selector("label", text: "Given name")
  end

  it "renders the requested input type" do
    render partial: "shared/field", locals: { form: form, attr: :email, as: :email }
    expect(rendered).to have_selector("input.input[type='email']")
  end

  it "renders a select from the given collection" do
    render partial: "shared/field", locals: {
      form: form, attr: :status, as: :select, collection: [ [ "Active", "active" ], [ "Inactive", "inactive" ] ]
    }
    expect(rendered).to have_selector("select.select.w-full#customer_status")
    expect(rendered).to have_selector("option[value='active']", text: "Active")
  end

  it "renders a textarea" do
    render partial: "shared/field", locals: { form: form, attr: :notes, as: :textarea }
    expect(rendered).to have_selector("textarea.textarea.w-full#customer_notes")
  end

  it "renders a hint linked via aria-describedby" do
    render partial: "shared/field", locals: { form: form, attr: :phone, hint: "Include area code" }
    expect(rendered).to have_selector("p#customer_phone_hint.form-hint", text: "Include area code")
    expect(rendered).to have_selector("input[aria-describedby='customer_phone_hint']")
  end

  it "marks an invalid field with aria-invalid and a linked inline error" do
    customer.first_name = nil
    customer.valid?

    render partial: "shared/field", locals: { form: form, attr: :first_name }

    expect(rendered).to have_selector("input[aria-invalid='true']")
    expect(rendered).to have_selector("input[aria-describedby='customer_first_name_error']")
    expect(rendered).to have_selector("p#customer_first_name_error.form-error")
  end
end
