require "rails_helper"

RSpec.describe "Jobs", type: :request do
  let(:customer) { create(:customer) }

  describe "GET /jobs" do
    it "renders the index" do
      create(:job, customer: customer)
      get jobs_path
      expect(response).to have_http_status(:success)
    end

    it "filters by the search query across title/customer name" do
      match_customer = create(:customer, first_name: "Zebra", last_name: "Findme")
      match    = create(:job, customer: match_customer, title: "Kitchen retile")
      no_match = create(:job, customer: customer, title: "Bathroom job")

      get jobs_path, params: { q: { title_or_customer_first_name_or_customer_last_name_cont: "Findme" } }

      expect(response.body).to include(match.title)
      expect(response.body).not_to include(no_match.title)
    end

    it "filters by status using the enum's integer value, not its label" do
      active_job  = create(:job, customer: customer, status: :active)
      on_hold_job = create(:job, customer: customer, status: :on_hold)

      get jobs_path, params: { q: { status_eq: Job.statuses["on_hold"] } }

      expect(response.body).to include(on_hold_job.title)
      expect(response.body).not_to include(active_job.title)
    end

    it "paginates when there are more jobs than one page" do
      jobs = create_list(:job, 21, customer: customer)
      last_job = jobs.max_by(&:id)

      get jobs_path
      expect(response.body).to include("page=2")
      expect(response.body).not_to include(last_job.title)

      get jobs_path, params: { page: 2 }
      expect(response.body).to include(last_job.title)
    end
  end

  describe "GET /jobs/:id" do
    it "renders the job" do
      job = create(:job, customer: customer)
      get job_path(job)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /jobs/new" do
    it "renders the form" do
      get new_job_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /jobs/:id/edit" do
    it "renders the form" do
      job = create(:job, customer: customer)
      get edit_job_path(job)
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /jobs" do
    it "creates a job and redirects to it" do
      params = { job: { title: "New job", customer_id: customer.id } }
      expect { post jobs_path, params: params }.to change(Job, :count).by(1)
      expect(response).to redirect_to(job_path(Job.last))
    end

    it "re-renders the form on invalid params" do
      params = { job: { title: "", customer_id: customer.id } }
      expect { post jobs_path, params: params }.not_to change(Job, :count)
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /jobs/:id" do
    it "updates and redirects" do
      job = create(:job, customer: customer)
      patch job_path(job), params: { job: { title: "Updated title" } }
      expect(response).to redirect_to(job_path(job))
      expect(job.reload.title).to eq("Updated title")
    end

    it "re-renders the form on invalid params" do
      job = create(:job, customer: customer)
      patch job_path(job), params: { job: { title: "" } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "DELETE /jobs/:id" do
    it "destroys the job and redirects when nothing blocks it" do
      job = create(:job, customer: customer)
      expect { delete job_path(job) }.to change(Job, :count).by(-1)
      expect(response).to redirect_to(jobs_path)
    end

    it "redirects with an alert and does not destroy when the job has an order" do
      job = create(:job, customer: customer)
      create(:order, job: job, customer: customer)

      expect { delete job_path(job) }.not_to change(Job, :count)
      expect(response).to redirect_to(jobs_path)
      expect(flash[:alert]).to eq("Could not delete job.")
    end
  end

  describe "restyled UI (Step 10)" do
    it "index: renders the page header, a status badge per row, and the row-actions popover trigger" do
      job = create(:job, customer: customer, status: :on_hold)
      get jobs_path

      expect(response.body).to include('<h1 class="text-xl font-semibold text-base-content">Jobs</h1>')
      expect(response.body).to include('href="' + new_job_path + '"')
      expect(response.body).to match(/badge badge-soft badge-warning">\s*On hold/)
      expect(response.body).to include("popovertarget=\"row-actions-job_#{job.id}\"")
    end

    it "show: renders the detail list, job site address, and Edit/Delete actions" do
      job = create(:job, customer: customer, address_line_1: "1 Main St", city: "Ottawa")
      get job_path(job)

      expect(response.body).to include('<dt class="text-xs font-semibold uppercase tracking-wide text-base-content/70">Job Site</dt>')
      expect(response.body).to include("1 Main St<br>Ottawa")
      expect(response.body).to include(">Edit<")
      expect(response.body).to include(">Delete<")
    end

    it "show: renders the Originated From section only when the job has a lead" do
      lead_job = create(:job, :from_lead, customer: customer)
      get job_path(lead_job)
      expect(response.body).to include("Originated From")
      expect(response.body).to include(lead_job.lead.title)

      plain_job = create(:job, customer: customer)
      get job_path(plain_job)
      expect(response.body).not_to include("Originated From")
    end

    it "show: renders an empty state for Orders when there are none" do
      job = create(:job, customer: customer)
      get job_path(job)
      expect(response.body).to include("No orders yet.")
      expect(response.body).to include('href="' + new_job_order_path(job) + '"')
    end

    it "form: has a blank prompt on Customer and None on Job Type" do
      get new_job_path
      expect(response.body).to match(%r{<option value="">Select a customer</option>})
      expect(response.body).to match(%r{<option value="">None</option>})
    end
  end
end
