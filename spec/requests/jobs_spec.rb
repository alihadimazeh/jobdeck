require "rails_helper"

RSpec.describe "Jobs", type: :request do
  let(:customer) { create(:customer) }

  describe "GET /jobs" do
    it "renders the index" do
      create(:job, customer: customer)
      get jobs_path
      expect(response).to have_http_status(:success)
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
end
