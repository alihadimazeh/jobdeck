require "rails_helper"

RSpec.describe "Application layout", type: :request do
  it "renders the themed document shell with a skip link and a focusable main landmark" do
    get customers_path

    expect(response.body).to include('<html lang="en" data-theme="jobdeck"')
    expect(response.body).to match(%r{<a href="#main"[^>]*>\s*Skip to content})
    expect(response.body).to include('id="main"')
    expect(response.body).to include('main id="main" tabindex="-1"')
  end

  it "renders the daisyUI drawer structure wired to a single toggle checkbox" do
    get customers_path

    expect(response.body).to include('<input id="app-drawer" type="checkbox" class="drawer-toggle">')
    expect(response.body).to include('drawer-side')
    # both the mobile hamburger and the overlay close-label target the same checkbox
    expect(response.body.scan('for="app-drawer"').size).to eq(2)
  end

  it "renders the primary sidebar nav with all three top-level sections" do
    get customers_path

    expect(response.body).to match(%r{<nav aria-label="Primary".*?</nav>}m)
    expect(response.body).to include(%(href="#{customers_path}"))
    expect(response.body).to include(%(href="#{leads_path}"))
    expect(response.body).to include(%(href="#{jobs_path}"))
  end

  it "keeps the breadcrumb/page_heading content_for mechanism working, with an accessible breadcrumb landmark" do
    customer = create(:customer)
    get customer_path(customer)

    expect(response.body).to include('<nav aria-label="Breadcrumb"')
    expect(response.body).to include(customer.full_name)
  end

  it "renders a dismissible, accessible flash after a redirect with a notice" do
    customer = create(:customer)
    patch customer_path(customer), params: { customer: { first_name: "Updated" } }
    follow_redirect!

    expect(response.body).to include('aria-live="polite"')
    expect(response.body).to match(/alert-success/)
    expect(response.body).to include("Customer was successfully updated.")
  end

  it "renders an alert-role flash after a redirect with an alert" do
    # deleting a customer with an order is blocked -> redirects back with an alert
    customer = create(:customer)
    job = create(:job, customer: customer)
    create(:order, job: job, customer: customer)

    delete customer_path(customer)
    follow_redirect!

    expect(response.body).to match(/alert-error/)
    expect(response.body).to include('role="alert"')
  end
end
