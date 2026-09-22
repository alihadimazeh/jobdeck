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

    expect(response.body).to include('<input id="app-drawer" type="checkbox" class="drawer-toggle" data-drawer-target="checkbox">')
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

  it "renders the page's breadcrumb landmark via shared/page_header, with no empty layout header" do
    customer = create(:customer)
    get customer_path(customer)

    expect(response.body).to include('<nav aria-label="Breadcrumb"')
    expect(response.body).to include(customer.full_name)
    expect(response.body.scan('aria-label="Breadcrumb"').size).to eq(1)
    # The old content_for(:breadcrumbs/:page_heading) block rendered an empty bordered
    # <header> banner on every page - nothing ever set either content_for.
    expect(response.body).not_to include("<header")
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
    # deleting a job with an order is blocked (dependent: :restrict_with_error) ->
    # redirects back with an alert. (Deleting a *customer* with history no longer
    # alerts as of feature/customer-archive - it archives instead and notices.)
    job = create(:job)
    create(:order, job: job, customer: job.customer)

    delete job_path(job)
    follow_redirect!

    expect(response.body).to match(/alert-error/)
    expect(response.body).to include('role="alert"')
  end
end
