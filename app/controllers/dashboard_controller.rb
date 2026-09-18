class DashboardController < ApplicationController
  PREVIEW_LIMIT = 5

  # GET /
  def show
    @follow_up_leads_count = Lead.needs_follow_up.count
    @follow_up_leads = Lead.needs_follow_up.includes(:customer).order(:follow_up_date).limit(PREVIEW_LIMIT)

    @active_jobs_count = Job.active_status.count
    @active_jobs = Job.active_status.includes(:customer).order(:start_date).limit(PREVIEW_LIMIT)

    @outstanding_orders_count = Order.outstanding.count
    @outstanding_orders = Order.outstanding.includes(:customer).order(:due_date).limit(PREVIEW_LIMIT)
  end
end
